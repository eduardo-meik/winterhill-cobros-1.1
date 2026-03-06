Email setup (Mailtrap + Supabase Edge)

This app sends transactional emails (receipts and pagares) via a Supabase Edge Function named `send-email`. It supports Mailtrap (recommended) and Resend. Follow these steps to configure Mailtrap.

Prerequisites
- A verified domain in Mailtrap Email Sending (not Sandbox)
- An API token for Mailtrap Email Sending
- A sender address from your verified domain (e.g. soporte@colegiowinterhill.cl)

Set function secrets in Supabase
1) Open Supabase Dashboard → Project Settings → Functions → Secrets → Add secrets:
   - EMAIL_PROVIDER=mailtrap
   - EMAIL_API_KEY=<your_mailtrap_api_token>
   - EMAIL_FROM=soporte@colegiowinterhill.cl

2) Deploy the function
   Using Supabase CLI (PowerShell):
   - supabase functions deploy send-email

   Or use the Dashboard "Deploy" for the `send-email` function.

3) Test from the app
- Payments → open a paid fee → click "Enviar Recibo". The email body is an HTML receipt.
- Matrícula → generate the Pagaré preview → click "Enviar por correo". The function will attach the PDF (<=10MB).

Audit and limits
- All email attempts are logged into `public.email_logs` with status sent/failed and provider message id.
- The function validates email addresses, max 5 attachments, total size <= 10MB.
- Add rate limiting later if needed (per user/IP window).

Do NOT keep provider tokens in the frontend
- Never expose provider secrets in VITE_* variables. Move them to function secrets as above. Remove `VITE_MAILTRAP_API_TOKEN` from your `.env` and keep tokens out of source control.

SMTP for Supabase Auth (optional)
- This is unrelated to transactional emails above. If you want Supabase Auth emails (confirm/reset) to go through Mailtrap SMTP:
  - Host: live.smtp.mailtrap.io
  - Port: 587 (STARTTLS)
  - Username: apismtp@mailtrap.io
  - Password: <your_mailtrap_api_token>
  - Sender email: soporte@colegiowinterhill.cl (must be verified domain)
  - Sender name: e.g. "Gestión Winterhill"
  If it fails, check Mailtrap logs, ensure SPF/DKIM are verified, and verify that it is Mailtrap Email Sending (not Sandbox).
