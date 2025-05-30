// supabase/functions/request-password-reset/index.ts
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*', // Or your specific frontend domain for better security
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS', // Specify allowed methods
};

Deno.serve(async (req: Request) => {
  // Handle OPTIONS request for CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: "Method Not Allowed" }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 405,
    });
  }

  let email: string;
  try {
    const body = await req.json();
    email = body.email;
    if (!email || typeof email !== 'string') {
      return new Response(JSON.stringify({ error: "Email is required and must be a string" }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      });
    }
  } catch (e) {
    console.error("Error parsing JSON body:", e);
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');
  // IMPORTANT: This SITE_URL should be your Vercel app's base URL
  // e.g., https://your-app-name.vercel.app
  const siteUrl = Deno.env.get('SITE_URL'); 

  if (!supabaseUrl || !supabaseAnonKey || !siteUrl) {
    console.error("Missing environment variables: SUPABASE_URL, SUPABASE_ANON_KEY, or SITE_URL");
    return new Response(JSON.stringify({ error: "Server configuration error" }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    });
  }

  const supabaseClient: SupabaseClient = createClient(supabaseUrl, supabaseAnonKey);
  
  // This is the URL where users will be redirected after clicking the reset link
  // It must be registered in your Supabase Auth settings under "Redirect URLs"
  const redirectTo = `${siteUrl}/reset-password`; 

  console.log(`Requesting password reset for email: ${email}, redirectTo: ${redirectTo}`);

  const { data, error } = await supabaseClient.auth.resetPasswordForEmail(email, {
    redirectTo: redirectTo,
  });

  if (error) {
    console.error("Supabase reset password error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: (error as any).status || 400, 
    });
  }

  console.log("Password reset email initiated successfully for:", email);
  return new Response(JSON.stringify({ message: "If an account with this email exists, a password reset link has been sent." }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    status: 200,
  });
});
