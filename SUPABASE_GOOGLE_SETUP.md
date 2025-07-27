# Supabase Google OAuth Configuration

## Prerequisites
You need from Google Cloud Console:
- ✅ Google Client ID
- ✅ Google Client Secret

## Step 1: Enable Google Provider in Supabase

1. Go to your [Supabase Dashboard](https://app.supabase.com/)
2. Select your project
3. Navigate to **Authentication** > **Providers** (in the left sidebar)
4. Find **Google** in the list of providers
5. Click the toggle to **Enable** Google

## Step 2: Configure Google Provider

1. In the Google provider settings, you'll see fields for:
   - **Enabled**: Make sure this is toggled ON
   - **Client ID**: Paste your Google Client ID here
   - **Client Secret**: Paste your Google Client Secret here

2. Click **Save** to save the configuration

## Step 3: Configure Site URL and Redirect URLs

1. Still in **Authentication**, click on **URL Configuration**
2. Set your **Site URL**: 
   - For development: `http://localhost:5173`
   - For production: `https://yourdomain.com`

3. Add **Redirect URLs** (click "Add URL" for each):
   - `http://localhost:5173/auth/callback`
   - `http://localhost:5174/auth/callback` (backup dev port)
   - `https://yourdomain.com/auth/callback` (when you have production domain)

## Step 4: Get Your Supabase Credentials

1. Go to **Settings** > **API** in your Supabase dashboard
2. Copy these values:
   - **URL**: Your Supabase project URL
   - **anon/public key**: Your anonymous key

## Step 5: Create Environment File

Create a `.env.local` file in your project root with:

```bash
VITE_SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
VITE_SUPABASE_ANON_KEY=your_anon_key_here
VITE_GOOGLE_CLIENT_ID=your_google_client_id_here.apps.googleusercontent.com
VITE_SITE_URL=http://localhost:5173
```

Replace the placeholder values with your actual credentials.

## Step 6: Test the Configuration

1. Restart your development server: `npm run dev`
2. Go to `http://localhost:5173/login`
3. Click the "Continuar con Google" button
4. You should be redirected to Google's OAuth consent screen

## Troubleshooting Common Issues

### Error: "provider is not enabled"
- ✅ Check that Google provider is enabled in Supabase
- ✅ Verify Client ID and Secret are correctly entered
- ✅ Make sure you clicked "Save" in Supabase

### Error: "invalid redirect URI"
- ✅ Check that redirect URIs in Google Console match exactly
- ✅ Verify Supabase redirect URLs are configured
- ✅ Make sure the callback URL format is correct

### Error: "unauthorized domain"
- ✅ Add authorized domains in Google Console OAuth consent screen
- ✅ Add JavaScript origins in Google Console credentials

## Need Help?

If you're still having issues, check:
1. Browser console for detailed error messages
2. Supabase dashboard logs (Authentication > Logs)
3. Google Cloud Console for any warnings

The most common issue is mismatched redirect URIs between Google Console and Supabase configuration.
