// supabase/functions/send-email/index.ts
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";

// CORS headers (keep permissive for now; tighten to your domain when ready)
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type Attachment = {
  filename: string;
  content: string; // base64-encoded
  type?: string; // mime type (optional)
};

type RequestBody = {
  to: string;
  subject: string;
  html: string;
  type?: "receipt" | "pagare" | "other";
  related_id?: string;
  attachments?: Attachment[];
};

const EMAIL_REGEX = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i;
const MAX_TOTAL_ATTACHMENT_BYTES = 10 * 1024 * 1024; // 10MB
const MAX_ATTACHMENTS = 5;

function base64ByteLength(b64: string): number {
  // Approximate: 3/4 of length minus padding
  const len = b64.length;
  let padding = 0;
  if (b64.endsWith("==")) padding = 2;
  else if (b64.endsWith("=")) padding = 1;
  return Math.floor((len * 3) / 4) - padding;
}

async function getAuthUser(req: Request, supabaseUrl: string, anonKey: string) {
  try {
    const authClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
    });
    const { data, error } = await authClient.auth.getUser();
    if (error) return null;
    return data.user ?? null;
  } catch {
    return null;
  }
}

async function sendViaResend(from: string, payload: RequestBody, apiKey: string) {
  const url = "https://api.resend.com/emails";
  const body: any = {
    from,
    to: payload.to,
    subject: payload.subject,
    html: payload.html,
  };
  if (payload.attachments && payload.attachments.length > 0) {
    body.attachments = payload.attachments.map((a) => ({
      filename: a.filename,
      content: a.content,
      ...(a.type ? { contentType: a.type } : {}),
    }));
  }

  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    const msg = data?.message || data?.error || `Provider error ${res.status}`;
    throw new Error(String(msg));
  }
  return { id: data?.id as string | undefined };
}

async function sendViaMailtrap(from: string, payload: RequestBody, apiKey: string) {
  // Mailtrap Email Sending API
  // Docs: https://api-docs.mailtrap.io/
  const url = "https://send.api.mailtrap.io/api/send";
  
  // Extract email and name from "Name <email@domain.com>" format
  const emailMatch = from.match(/<(.+?)>/);
  const email = emailMatch ? emailMatch[1] : from;
  const namePart = emailMatch ? from.replace(/<.+?>/, '').trim() : '';
  
  const body: any = {
    from: { 
      email,
      ...(namePart ? { name: namePart } : {})
    },
    to: [{ email: payload.to }],
    subject: payload.subject,
    html: payload.html,
  };
  if (payload.attachments && payload.attachments.length > 0) {
    body.attachments = payload.attachments.map((a) => ({
      filename: a.filename,
      content: a.content, // base64
      type: a.type || undefined,
      disposition: "attachment",
    }));
  }

  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    const msg = data?.message || data?.error || `Provider error ${res.status}`;
    throw new Error(String(msg));
  }
  // Mailtrap typically returns message_ids array
  const id = (data?.message_ids && Array.isArray(data.message_ids) && data.message_ids[0]) || data?.id;
  return { id: id as string | undefined };
}

Deno.serve(async (req: Request) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method Not Allowed" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 405,
    });
  }

  let body: RequestBody;
  try {
    body = await req.json();
  } catch (e) {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }

  if (!body?.to || typeof body.to !== "string" || !EMAIL_REGEX.test(body.to)) {
    return new Response(JSON.stringify({ error: "Invalid 'to' email" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
  if (!body?.subject || typeof body.subject !== "string") {
    return new Response(JSON.stringify({ error: "'subject' is required" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
  if (!body?.html || typeof body.html !== "string") {
    return new Response(JSON.stringify({ error: "'html' is required" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }

  // Validate attachments
  if (body.attachments && !Array.isArray(body.attachments)) {
    return new Response(JSON.stringify({ error: "'attachments' must be an array" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
  if (body.attachments && body.attachments.length > MAX_ATTACHMENTS) {
    return new Response(JSON.stringify({ error: `Too many attachments (max ${MAX_ATTACHMENTS})` }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
  if (body.attachments && body.attachments.length > 0) {
    const totalBytes = body.attachments.reduce((acc, a) => acc + base64ByteLength(a.content || ""), 0);
    if (totalBytes > MAX_TOTAL_ATTACHMENT_BYTES) {
      return new Response(JSON.stringify({ error: "Attachments exceed 10MB total size" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      });
    }
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const provider = (Deno.env.get("EMAIL_PROVIDER") || "mailtrap").toLowerCase();
  const apiKey = Deno.env.get("EMAIL_API_KEY");
  const from = Deno.env.get("EMAIL_FROM");

  console.log("Configuration check:", {
    hasSupabaseUrl: !!supabaseUrl,
    hasAnonKey: !!supabaseAnonKey,
    hasServiceKey: !!supabaseServiceKey,
    provider,
    hasApiKey: !!apiKey,
    from: from ? `${from.substring(0, 10)}...` : 'NOT SET',
  });

  if (!supabaseUrl || !supabaseAnonKey || !supabaseServiceKey) {
    return new Response(JSON.stringify({ error: "Server configuration error (Supabase keys)" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
  if (!apiKey || !from) {
    return new Response(JSON.stringify({ error: `Email provider not configured. Missing: ${!apiKey ? 'EMAIL_API_KEY' : ''} ${!from ? 'EMAIL_FROM' : ''}` }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }

  const adminClient: SupabaseClient = createClient(supabaseUrl, supabaseServiceKey);
  const user = await getAuthUser(req, supabaseUrl, supabaseAnonKey);
  const userId = user?.id ?? null;

  let providerMessageId: string | undefined;
  let status: "sent" | "failed" = "sent";
  let errorMsg: string | null = null;

  console.log(`Attempting to send email via ${provider} to ${body.to}`);

  try {
    if (provider === "resend") {
      const res = await sendViaResend(from, body, apiKey);
      providerMessageId = res.id;
      console.log(`Email sent via Resend, ID: ${providerMessageId}`);
    } else if (provider === "mailtrap") {
      const res = await sendViaMailtrap(from, body, apiKey);
      providerMessageId = res.id;
      console.log(`Email sent via Mailtrap, ID: ${providerMessageId}`);
    } else {
      throw new Error(`Unsupported EMAIL_PROVIDER: ${provider}`);
    }
  } catch (err: any) {
    status = "failed";
    errorMsg = String(err?.message ?? err);
    console.error(`Email send failed: ${errorMsg}`);
  }

  // Log outcome (service role bypasses RLS)
  // Don't fail the request if logging fails
  try {
    await adminClient.from("email_logs").insert({
      type: body.type ?? "other",
      to_email: body.to,
      related_id: body.related_id ?? null,
      user_id: userId,
      provider_message_id: providerMessageId ?? null,
      status,
      error: errorMsg,
    });
  } catch (logError: any) {
    console.error("Failed to log email:", logError);
    // Continue anyway - logging shouldn't break email sending
  }

  if (status === "failed") {
    return new Response(JSON.stringify({ error: errorMsg }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 502,
    });
  }

  return new Response(
    JSON.stringify({ id: providerMessageId, status: "sent" }),
    { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
  );
});
