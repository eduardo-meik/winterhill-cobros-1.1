import React from 'react';

export function GoogleAuthDebug() {
  const envVars = {
    VITE_GOOGLE_CLIENT_ID: import.meta.env.VITE_GOOGLE_CLIENT_ID,
    VITE_SUPABASE_URL: import.meta.env.VITE_SUPABASE_URL,
    VITE_SITE_URL: import.meta.env.VITE_SITE_URL,
    NODE_ENV: import.meta.env.NODE_ENV,
    MODE: import.meta.env.MODE
  };

  return (
    <div className="fixed bottom-4 right-4 p-4 bg-gray-800 text-white rounded-lg shadow-lg z-50 max-w-md">
      <h3 className="font-bold mb-2">Google Auth Debug Info</h3>
      <div className="text-xs space-y-1">
        {Object.entries(envVars).map(([key, value]) => (
          <div key={key}>
            <strong>{key}:</strong> {value ? '✅ Set' : '❌ Missing'}
            {key === 'VITE_GOOGLE_CLIENT_ID' && value && (
              <div className="text-green-400">Client ID: {String(value).substring(0, 20)}...</div>
            )}
          </div>
        ))}
      </div>
      <div className="mt-2 pt-2 border-t border-gray-600">
        <strong>Window Origin:</strong> {window.location.origin}
      </div>
    </div>
  );
}
