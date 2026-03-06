# Google Authentication Setup Guide

## Overview
This guide provides step-by-step instructions for setting up Google OAuth authentication with Supabase for production deployment.

## Prerequisites
- Supabase project set up
- Google Cloud Console access
- Domain name for production (required for Google OAuth)

## 1. Google Cloud Console Setup

### Step 1: Create a Google Cloud Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google+ API (if not already enabled)

### Step 2: Configure OAuth Consent Screen
1. Navigate to "APIs & Services" > "OAuth consent screen"
2. Choose "External" for user type
3. Fill in the required information:
   - App name: "Winterhill Cobros"
   - User support email: Your support email
   - App logo: Your app logo (optional)
   - App domain: Your production domain
   - Authorized domains: Add your production domain
   - Developer contact information: Your email

### Step 3: Create OAuth 2.0 Credentials
1. Navigate to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth 2.0 Client ID"
3. Choose "Web application"
4. Set the name: "Winterhill Cobros Web Client"
5. Add Authorized JavaScript origins:
   - `https://your-domain.com` (production)
   - `http://localhost:5173` (development - optional)
6. Add Authorized redirect URIs:
   - `https://your-supabase-project.supabase.co/auth/v1/callback`
   - `http://localhost:5173/auth/callback` (development - optional)
7. Save and copy the Client ID

## 2. Supabase Configuration

### Step 1: Enable Google Provider
1. Go to your Supabase dashboard
2. Navigate to Authentication > Providers
3. Find Google and click "Enable"
4. Enter your Google OAuth Client ID
5. Enter your Google OAuth Client Secret (from Google Cloud Console)
6. Save the configuration

### Step 2: Configure Site URL
1. In Supabase dashboard, go to Authentication > URL Configuration
2. Set Site URL to your production domain: `https://your-domain.com`
3. Add redirect URLs:
   - `https://your-domain.com/auth/callback`
   - `http://localhost:5173/auth/callback` (for development)

## 3. Environment Variables

### Production Environment (.env.production)
```bash
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
VITE_GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
VITE_SITE_URL=https://your-domain.com
```

### Development Environment (.env.local)
```bash
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
VITE_GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
VITE_SITE_URL=http://localhost:5173
```

## 4. Database Considerations

The Google OAuth integration automatically handles user creation in Supabase. When a user signs in with Google:

1. A new user record is created in `auth.users`
2. User metadata includes Google profile information
3. The user's email is automatically verified
4. You may want to create a trigger to insert additional user data into your custom tables

### Example trigger for custom user data:
```sql
-- Function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, created_at)
  VALUES (new.id, new.email, now());
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
```

## 5. Security Best Practices

### Client-Side Security
- Never expose the Google Client Secret in client-side code
- Use HTTPS in production
- Implement proper CORS policies
- Validate tokens on the server side

### Supabase Security
- Enable Row Level Security (RLS) on all tables
- Use proper role-based access control
- Regularly rotate API keys
- Monitor authentication logs

### Example RLS Policy:
```sql
-- Allow users to read their own data
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

-- Allow users to update their own data
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);
```

## 6. Deployment Checklist

### Before Going Live:
- [ ] Google OAuth consent screen approved (if using external users)
- [ ] Production domain configured in Google Cloud Console
- [ ] Supabase providers configured correctly
- [ ] Environment variables set correctly
- [ ] Database triggers and RLS policies in place
- [ ] SSL certificate configured
- [ ] CORS policies configured
- [ ] Error monitoring set up

### Testing:
- [ ] Test Google login flow in production environment
- [ ] Verify user data is created correctly
- [ ] Test logout functionality
- [ ] Verify session persistence
- [ ] Test error handling scenarios

## 7. Monitoring and Troubleshooting

### Common Issues:
1. **"Invalid redirect URI"** - Check Google Console redirect URIs match exactly
2. **"Invalid client ID"** - Verify environment variables are correct
3. **"Unauthorized domain"** - Ensure domain is added to authorized domains
4. **Session not persisting** - Check Supabase client configuration

### Monitoring:
- Monitor authentication events in Supabase dashboard
- Set up error logging for failed authentication attempts
- Track user sign-up patterns
- Monitor for suspicious authentication activities

## 8. Advanced Configuration

### Custom Scopes:
If you need additional Google data, you can request additional scopes:

```typescript
export const signInWithGoogle = async () => {
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      scopes: 'profile email',
      redirectTo: `${window.location.origin}/auth/callback`,
      queryParams: {
        access_type: 'offline',
        prompt: 'consent',
      },
    }
  });
  // ... rest of the function
};
```

### Custom Claims:
You can add custom claims to the JWT token using Supabase Edge Functions.

## Support
For additional support:
- [Supabase Documentation](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Google OAuth Documentation](https://developers.google.com/identity/protocols/oauth2)
- [React + Supabase Auth Guide](https://supabase.com/docs/guides/auth/auth-helpers/react)
