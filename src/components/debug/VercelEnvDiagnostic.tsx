export function VercelEnvDiagnostic() {
  // Only show in production to diagnose Vercel specifically
  if (import.meta.env.DEV) {
    return null;
  }

  const allEnvVars = import.meta.env;
  const requiredVars = {
    VITE_SUPABASE_URL: import.meta.env.VITE_SUPABASE_URL,
    VITE_SUPABASE_ANON_KEY: import.meta.env.VITE_SUPABASE_ANON_KEY,
    VITE_GOOGLE_CLIENT_ID: import.meta.env.VITE_GOOGLE_CLIENT_ID,
    VITE_SITE_URL: import.meta.env.VITE_SITE_URL,
  };

  const systemInfo = {
    MODE: import.meta.env.MODE,
    DEV: import.meta.env.DEV,
    PROD: import.meta.env.PROD,
    SSR: import.meta.env.SSR,
    BASE_URL: import.meta.env.BASE_URL,
  };

  // Get all VITE_ prefixed variables
  const viteVars = Object.keys(allEnvVars)
    .filter(key => key.startsWith('VITE_'))
    .reduce((obj, key) => {
      obj[key] = allEnvVars[key];
      return obj;
    }, {} as Record<string, any>);

  const hasAllRequired = Object.values(requiredVars).every(val => !!val);
  const deploymentTime = new Date().toISOString();

  return (
    <div className="fixed bottom-4 right-4 z-50 max-w-md">
      <details className="bg-white border border-gray-300 rounded-lg shadow-lg">
        <summary className={`cursor-pointer p-3 rounded-t-lg font-medium ${
          hasAllRequired 
            ? 'bg-green-50 text-green-800 border-green-200' 
            : 'bg-red-50 text-red-800 border-red-200'
        }`}>
          🔍 Vercel Environment Diagnostic
          <span className="ml-2 text-sm">
            {hasAllRequired ? '✅ All OK' : '❌ Issues Found'}
          </span>
        </summary>
        
        <div className="p-4 space-y-4 max-h-96 overflow-y-auto text-xs">
          {/* Deployment Info */}
          <div className="border-b pb-2">
            <h4 className="font-semibold text-gray-700 mb-1">Deployment Info</h4>
            <div className="text-gray-600">
              <div>Checked at: {deploymentTime}</div>
              <div>Mode: {systemInfo.MODE}</div>
              <div>Environment: {systemInfo.PROD ? 'Production' : 'Development'}</div>
              <div>Base URL: {systemInfo.BASE_URL}</div>
            </div>
          </div>

          {/* Required Variables Status */}
          <div className="border-b pb-2">
            <h4 className="font-semibold text-gray-700 mb-1">Required Variables</h4>
            {Object.entries(requiredVars).map(([key, value]) => (
              <div key={key} className="flex items-center justify-between py-1">
                <span className="font-mono text-gray-600">{key}:</span>
                <div className="flex items-center space-x-2">
                  <span className={value ? "text-green-600" : "text-red-600"}>
                    {value ? "✅" : "❌"}
                  </span>
                  {value && key.includes('URL') && (
                    <span className="text-xs text-gray-500 truncate max-w-32">
                      {String(value).substring(0, 30)}...
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>

          {/* All VITE Variables */}
          <div className="border-b pb-2">
            <h4 className="font-semibold text-gray-700 mb-1">
              All VITE_ Variables ({Object.keys(viteVars).length})
            </h4>
            {Object.keys(viteVars).length === 0 ? (
              <div className="text-red-600 text-xs">❌ No VITE_ variables found!</div>
            ) : (
              <div className="space-y-1">
                {Object.entries(viteVars).map(([key, value]) => (
                  <div key={key} className="flex items-center justify-between py-1">
                    <span className="font-mono text-gray-600 text-xs">{key}:</span>
                    <span className={value ? "text-green-600" : "text-red-600"}>
                      {value ? "✅" : "❌"}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Troubleshooting */}
          {!hasAllRequired && (
            <div className="bg-yellow-50 p-2 rounded border">
              <h4 className="font-semibold text-yellow-800 mb-1">🔧 Troubleshooting</h4>
              <div className="text-yellow-700 text-xs space-y-1">
                <div>1. Check Vercel Dashboard → Settings → Environment Variables</div>
                <div>2. Ensure variables are set for "Production" environment</div>
                <div>3. Redeploy after adding variables</div>
                <div>4. Variables must start with "VITE_" prefix</div>
              </div>
            </div>
          )}

          {/* Success Message */}
          {hasAllRequired && (
            <div className="bg-green-50 p-2 rounded border border-green-200">
              <div className="text-green-700 text-xs">
                ✅ All environment variables are properly configured!
              </div>
            </div>
          )}
        </div>
      </details>
    </div>
  );
}
