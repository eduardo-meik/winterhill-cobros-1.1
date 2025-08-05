export function ProductionEnvCheck() {
  const env = {
    VITE_SUPABASE_URL: import.meta.env.VITE_SUPABASE_URL,
    VITE_SUPABASE_ANON_KEY: import.meta.env.VITE_SUPABASE_ANON_KEY,
    VITE_GOOGLE_CLIENT_ID: import.meta.env.VITE_GOOGLE_CLIENT_ID,
    VITE_SITE_URL: import.meta.env.VITE_SITE_URL,
    MODE: import.meta.env.MODE,
    DEV: import.meta.env.DEV,
    PROD: import.meta.env.PROD
  };

  const hasRequiredVars = env.VITE_SUPABASE_URL && 
                         env.VITE_SUPABASE_ANON_KEY && 
                         env.VITE_GOOGLE_CLIENT_ID && 
                         env.VITE_SITE_URL;

  if (hasRequiredVars) {
    return null; // Don't show anything if all vars are present
  }

  return (
    <div className="fixed top-0 left-0 right-0 z-50 bg-red-100 border border-red-400 text-red-700 px-4 py-3">
      <div className="flex items-center justify-between">
        <div>
          <strong className="font-bold">⚠️ Environment Configuration Issue:</strong>
          <span className="block sm:inline"> Missing required environment variables in production.</span>
          <span className="block text-sm mt-1">Please configure environment variables in Vercel dashboard.</span>
        </div>
        <details className="cursor-pointer">
          <summary className="text-sm underline">Show Details</summary>
          <div className="mt-2 text-xs space-y-1">
            {Object.entries(env).map(([key, value]) => (
              <div key={key} className="flex justify-between">
                <span className="font-mono">{key}:</span>
                <span className={value ? "text-green-600" : "text-red-600"}>
                  {value ? "✅ Set" : "❌ Missing"}
                </span>
              </div>
            ))}
          </div>
        </details>
      </div>
    </div>
  );
}
