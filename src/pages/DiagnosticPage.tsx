export function DiagnosticPage() {
  const envStatus = {
    VITE_SUPABASE_URL: !!import.meta.env.VITE_SUPABASE_URL,
    VITE_SUPABASE_ANON_KEY: !!import.meta.env.VITE_SUPABASE_ANON_KEY,
    VITE_GOOGLE_CLIENT_ID: !!import.meta.env.VITE_GOOGLE_CLIENT_ID,
    VITE_SITE_URL: !!import.meta.env.VITE_SITE_URL,
  };

  const urls = {
    VITE_SUPABASE_URL: import.meta.env.VITE_SUPABASE_URL,
    VITE_SITE_URL: import.meta.env.VITE_SITE_URL,
  };

  const systemInfo = {
    MODE: import.meta.env.MODE,
    DEV: import.meta.env.DEV,
    PROD: import.meta.env.PROD,
    BASE_URL: import.meta.env.BASE_URL,
    timestamp: new Date().toISOString(),
    userAgent: navigator.userAgent,
    url: window.location.href,
    origin: window.location.origin,
  };

  const allGood = Object.values(envStatus).every(Boolean);

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-4xl mx-auto px-4">
        <div className="bg-white rounded-lg shadow-lg p-6">
          <h1 className="text-2xl font-bold mb-6 text-center">
            🔍 Environment Variables Diagnostic
          </h1>
          
          <div className={`p-4 rounded-lg mb-6 text-center ${
            allGood 
              ? 'bg-green-50 border border-green-200 text-green-800' 
              : 'bg-red-50 border border-red-200 text-red-800'
          }`}>
            <h2 className="text-xl font-semibold">
              {allGood ? '✅ All Environment Variables OK' : '❌ Missing Environment Variables'}
            </h2>
            <p className="mt-2 text-sm">
              {allGood 
                ? 'Your Vercel deployment has all required environment variables configured.'
                : 'Some required environment variables are missing. Check your Vercel dashboard configuration.'
              }
            </p>
          </div>

          <div className="grid md:grid-cols-2 gap-6">
            {/* Environment Variables Status */}
            <div className="bg-gray-50 p-4 rounded-lg">
              <h3 className="font-semibold text-lg mb-3">Required Variables</h3>
              <div className="space-y-2">
                {Object.entries(envStatus).map(([key, isSet]) => (
                  <div key={key} className="flex items-center justify-between p-2 bg-white rounded border">
                    <span className="font-mono text-sm">{key}</span>
                    <span className={`font-semibold ${isSet ? 'text-green-600' : 'text-red-600'}`}>
                      {isSet ? '✅ SET' : '❌ MISSING'}
                    </span>
                  </div>
                ))}
              </div>
            </div>

            {/* URL Values */}
            <div className="bg-gray-50 p-4 rounded-lg">
              <h3 className="font-semibold text-lg mb-3">URL Values</h3>
              <div className="space-y-2">
                {Object.entries(urls).map(([key, value]) => (
                  <div key={key} className="p-2 bg-white rounded border">
                    <div className="font-mono text-sm text-gray-600">{key}:</div>
                    <div className="text-xs break-all mt-1">
                      {value || <span className="text-red-500">Not set</span>}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* System Information */}
          <div className="mt-6 bg-gray-50 p-4 rounded-lg">
            <h3 className="font-semibold text-lg mb-3">System Information</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-2 text-sm">
              {Object.entries(systemInfo).map(([key, value]) => (
                <div key={key} className="flex justify-between p-2 bg-white rounded border">
                  <span className="font-mono text-gray-600">{key}:</span>
                  <span className="text-right break-all max-w-xs">
                    {typeof value === 'boolean' ? (value ? 'true' : 'false') : String(value)}
                  </span>
                </div>
              ))}
            </div>
          </div>

          {/* Instructions */}
          <div className="mt-6 bg-blue-50 p-4 rounded-lg border border-blue-200">
            <h3 className="font-semibold text-lg mb-3 text-blue-800">📋 How to Fix Missing Variables</h3>
            <ol className="list-decimal list-inside space-y-2 text-blue-700 text-sm">
              <li>Go to your Vercel project dashboard</li>
              <li>Navigate to Settings → Environment Variables</li>
              <li>Add each missing variable with the correct value</li>
              <li>Make sure to select "Production" environment</li>
              <li>Redeploy your application</li>
              <li>Return to this page to verify the fix</li>
            </ol>
          </div>

          <div className="mt-6 text-center">
            <button 
              onClick={() => window.location.reload()} 
              className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 transition-colors"
            >
              🔄 Refresh Check
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
