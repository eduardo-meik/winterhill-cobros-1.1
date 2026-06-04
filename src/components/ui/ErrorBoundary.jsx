import React from 'react';

export class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    console.error('[ErrorBoundary] ERROR CAPTURADO:', error);
    console.error('[ErrorBoundary] Component stack:', errorInfo?.componentStack);
  }

  render() {
    if (this.state.hasError) {
      const err = this.state.error;
      return (
        <div className="flex flex-col items-center justify-center min-h-[50vh] p-8 text-center">
          <div className="rounded-full bg-red-100 dark:bg-red-900/30 p-4 mb-4">
            <svg className="h-10 w-10 text-red-600 dark:text-red-400" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z" />
            </svg>
          </div>
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
            Algo salió mal
          </h2>
          <p className="text-sm text-gray-600 dark:text-gray-400 mb-2 max-w-md">
            Ocurrió un error inesperado. Intenta recargar la página.
          </p>
          {/* ── DEBUG: error real visible ── */}
          <div className="my-4 p-4 bg-red-50 dark:bg-red-900/20 border border-red-300 dark:border-red-700 rounded-lg text-left max-w-2xl w-full overflow-auto">
            <p className="text-sm font-bold text-red-800 dark:text-red-300 mb-1">Error:</p>
            <pre className="text-xs text-red-700 dark:text-red-400 whitespace-pre-wrap break-words">
              {err?.message || String(err)}
            </pre>
            {err?.stack && (
              <>
                <p className="text-sm font-bold text-red-800 dark:text-red-300 mt-3 mb-1">Stack:</p>
                <pre className="text-xs text-red-700 dark:text-red-400 whitespace-pre-wrap break-words max-h-48 overflow-auto">
                  {err.stack}
                </pre>
              </>
            )}
          </div>
          {/* ── FIN DEBUG ── */}
          <button
            onClick={() => window.location.reload()}
            className="inline-flex items-center px-4 py-2 rounded-md bg-primary text-white text-sm font-medium hover:bg-primary/90 transition-colors"
          >
            Recargar página
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}
