import { supabase } from './supabase';

export type EmailAttachment = {
  filename: string;
  content: string; // base64
  type?: string; // mime type
};

export type SendEmailPayload = {
  to: string;
  subject: string;
  html: string;
  type?: 'receipt' | 'pagare' | 'other' | 'comprobante' | 'prestacion';
  related_id?: string;
  attachments?: EmailAttachment[];
};

export async function sendEmailViaFunction(payload: SendEmailPayload) {
  try {
    const response = await supabase.functions.invoke('send-email', {
      body: payload,
    });
    
    if (import.meta.env.DEV) {
      console.log('Function invoke status:', response.data?.status ?? 'unknown');
    }
    
    const { data, error } = response;
    
    // If there's a network/invoke error with context
    if (error && error.context) {
      // Try to read the response body
      try {
        const responseText = await error.context.text();
        if (import.meta.env.DEV) {
          console.error('Error response body:', responseText);
        }
        const errorData = JSON.parse(responseText);
        throw new Error(errorData.error || errorData.message || 'Unknown error');
      } catch (parseError) {
        if (import.meta.env.DEV) {
          console.error('Could not parse error response:', parseError);
        }
        throw new Error(error.message || 'Edge Function error');
      }
    }
    
    // If there's a network/invoke error without context
    if (error) {
      if (import.meta.env.DEV) {
        console.error('Edge Function invocation error:', error.message);
      }
      throw new Error(error.message || 'Unknown error');
    }
    
    // If the function returned an error response
    if (data?.error) {
      if (import.meta.env.DEV) {
        console.error('Edge Function returned error:', data.error);
      }
      throw new Error(data.error);
    }
    
    return data as { id?: string; status: string };
  } catch (err: any) {
    if (import.meta.env.DEV) {
      console.error('sendEmailViaFunction caught error:', err?.message || err);
    }
    throw err;
  }
}

export async function blobToBase64(blob: Blob): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      const result = reader.result as string;
      // result is a data URL like "data:application/pdf;base64,...."; strip the prefix
      const base64 = result.split(',')[1] || '';
      resolve(base64);
    };
    reader.onerror = reject;
    reader.readAsDataURL(blob);
  });
}
