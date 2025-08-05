import React from 'react';

export function EnvTest() {
  const env = {
    VITE_SUPABASE_URL: import.meta.env.VITE_SUPABASE_URL,
    VITE_SUPABASE_ANON_KEY: import.meta.env.VITE_SUPABASE_ANON_KEY,
    VITE_GOOGLE_CLIENT_ID: import.meta.env.VITE_GOOGLE_CLIENT_ID,
    VITE_SITE_URL: import.meta.env.VITE_SITE_URL,
    NODE_ENV: import.meta.env.NODE_ENV,
    MODE: import.meta.env.MODE,
    DEV: import.meta.env.DEV,
    PROD: import.meta.env.PROD
  };

  return (
    <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
      <h3 className="font-bold text-blue-900 mb-2">Environment Variables Test</h3>
      <div className="space-y-1 text-sm">
        {Object.entries(env).map(([key, value]) => (
          <div key={key} className="flex justify-between">
            <span className="font-mono text-blue-800">{key}:</span>
            <span className={value ? "text-green-600" : "text-red-600"}>
              {value ? "✅ Set" : "❌ Missing"}
              {key.includes('URL') && value && (
                <span className="ml-2 text-xs text-gray-600">({String(value)})</span>
              )}
            </span>
          </div>
        ))}
      </div>
      <div className="mt-2 pt-2 border-t border-blue-200">
        <div className="text-xs text-blue-700">
          <strong>Origin:</strong> {window.location.origin}
        </div>
      </div>
    </div>
  );
}
