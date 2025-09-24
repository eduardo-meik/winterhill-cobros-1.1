# Custom Domain Configuration Guide

## Current Issue
- Working URL: https://winterhill-cobros-6s5iqxhr0-eduardomeiks-projects.vercel.app ✅
- Custom Domain: https://gestion.colegiowinterhill.cl ❌ (showing old version)

## Solution Steps

### 1. Vercel Domain Configuration
1. Go to Vercel Dashboard
2. Find the OLD project that has `gestion.colegiowinterhill.cl`
3. Remove the domain from the old project
4. Add the domain to the current project: `winterhill-cobros-6s5iqxhr0`

### 2. Environment Variables Update
Update `VITE_SITE_URL` in Vercel dashboard to:
```
VITE_SITE_URL=https://gestion.colegiowinterhill.cl
```

### 3. Google OAuth Update
In Google Cloud Console, update OAuth settings:
- **Authorized JavaScript origins**: `https://gestion.colegiowinterhill.cl`
- **Authorized redirect URIs**: `https://gestion.colegiowinterhill.cl/auth/callback`

### 4. Verification
After changes:
- Test: https://gestion.colegiowinterhill.cl/login
- Should show the same version as the working Vercel URL
- Google login should work properly

## Expected Result
Both URLs should show the same current version:
- ✅ https://winterhill-cobros-6s5iqxhr0-eduardomeiks-projects.vercel.app
- ✅ https://gestion.colegiowinterhill.cl
