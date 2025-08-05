import { useAuth } from '../../contexts/AuthContext';

interface GoogleAuthButtonProps {
  text?: string;
  disabled?: boolean;
  className?: string;
}

export function GoogleAuthButton({ 
  text = 'Continuar con Google', 
  disabled = false,
  className = '' 
}: GoogleAuthButtonProps) {
  const { signInWithGoogle, loading } = useAuth();

  // Check if Google Client ID is available
  const googleClientId = import.meta.env.VITE_GOOGLE_CLIENT_ID;
  
  // Debug info in development
  if (import.meta.env.DEV) {
    console.log('🔍 GoogleAuthButton Debug:', {
      hasGoogleClientId: !!googleClientId,
      loading,
      disabled,
      text
    });
  }

  // Don't render if Google OAuth is not configured
  if (!googleClientId) {
    console.warn('GoogleAuthButton: Google Client ID not found - button will not be rendered');
    
    // Show a warning in development
    if (import.meta.env.DEV) {
      return (
        <div className="w-full p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
          <p className="text-sm text-yellow-800">
            ⚠️ Google OAuth no configurado (VITE_GOOGLE_CLIENT_ID no encontrado)
          </p>
        </div>
      );
    }
    
    return null;
  }

  const handleGoogleSignIn = async () => {
    try {
      console.log('🚀 Google sign-in button clicked');
      await signInWithGoogle();
    } catch (error) {
      // Error is handled by the AuthContext
      console.error('Google sign-in error:', error);
    }
  };

  return (
    <button
      type="button"
      onClick={handleGoogleSignIn}
      disabled={disabled || loading}
      className={`
        w-full inline-flex justify-center items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm bg-white text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary disabled:opacity-50 disabled:cursor-not-allowed transition-colors
        dark:bg-dark-card dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700
        ${className}
      `}
    >
      {loading ? (
        <>
          <svg 
            className="animate-spin -ml-1 mr-3 h-5 w-5 text-gray-400" 
            xmlns="http://www.w3.org/2000/svg" 
            fill="none" 
            viewBox="0 0 24 24"
          >
            <circle 
              className="opacity-25" 
              cx="12" 
              cy="12" 
              r="10" 
              stroke="currentColor" 
              strokeWidth="4"
            />
            <path 
              className="opacity-75" 
              fill="currentColor" 
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
            />
          </svg>
          Conectando...
        </>
      ) : (
        <>
          <svg 
            className="w-5 h-5 mr-2" 
            viewBox="0 0 24 24" 
            xmlns="http://www.w3.org/2000/svg"
          >
            <path 
              fill="#4285F4" 
              d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
            />
            <path 
              fill="#34A853" 
              d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
            />
            <path 
              fill="#FBBC05" 
              d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
            />
            <path 
              fill="#EA4335" 
              d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
            />
          </svg>
          {text}
        </>
      )}
    </button>
  );
}
