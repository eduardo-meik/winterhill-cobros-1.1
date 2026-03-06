# Google Cloud Console Setup - Step by Step Guide

## Step 1: Create/Access Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Either create a new project or select an existing one
3. Make note of your project ID

## Step 2: Enable Google+ API (if needed)

1. In the Google Cloud Console, go to "APIs & Services" > "Library"
2. Search for "Google+ API" 
3. Click on it and enable it (if not already enabled)

## Step 3: Configure OAuth Consent Screen

1. Go to "APIs & Services" > "OAuth consent screen"
2. Choose "External" for user type (unless you have a Google Workspace)
3. Fill in the required information:
   - **App name**: `Winterhill Cobros` (or your preferred name)
   - **User support email**: Your email address
   - **App logo**: Upload your app logo (optional but recommended)
   - **App domain**: Leave blank for now (add your production domain later)
   - **Authorized domains**: 
     - Add `supabase.co` 
     - Add your production domain when you have one
   - **Developer contact information**: Your email address

4. Click "Save and Continue"
5. On "Scopes" page, click "Save and Continue" (default scopes are fine)
6. On "Test users" page, add your email for testing, then "Save and Continue"

## Step 4: Create OAuth 2.0 Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth 2.0 Client ID"
3. Choose "Web application"
4. Set the name: `Winterhill Cobros Web Client`
5. **Authorized JavaScript origins**: Add these URLs:
   - `http://localhost:5173` (for development)
   - `http://localhost:5174` (alternative dev port)
   - Your production domain when ready (e.g., `https://yourapp.com`)

6. **Authorized redirect URIs**: Add these URLs:
   - For development: `http://localhost:5173/auth/callback`
   - For development: `http://localhost:5174/auth/callback`
   - **MOST IMPORTANT**: `https://YOUR_SUPABASE_PROJECT_ID.supabase.co/auth/v1/callback`
   
   Replace `YOUR_SUPABASE_PROJECT_ID` with your actual Supabase project ID

7. Click "Create"
8. **COPY AND SAVE**: 
   - Client ID (you'll need this)
   - Client Secret (you'll need this for Supabase)

## What you'll need for the next step:
- ✅ Google Client ID
- ✅ Google Client Secret  
- ✅ Your Supabase Project URL

## Next: Configure Supabase (see next guide)
