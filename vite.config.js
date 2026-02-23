import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig(({ mode }) => {
  // SECURITY FIX: No hardcoded fallback URL — require explicit env var or use runtime origin
  if (mode === 'production' && !process.env.VITE_SITE_URL) {
    console.warn('⚠️  VITE_SITE_URL not set. The app will use window.location.origin as fallback at runtime.');
  }

  return {
    plugins: [react()],
    build: {
      outDir: 'dist',
      // SECURITY FIX: Disable source maps in production to prevent source code exposure
      sourcemap: mode !== 'production',
      minify: 'terser',
      terserOptions: {
        compress: {
          drop_console: true,
          drop_debugger: true
        }
      }
    },
    resolve: {
      alias: {
        '@': path.resolve(__dirname, './src'),
      },
    },
    optimizeDeps: {
      include: ['react', 'react-dom', 'recharts', '@headlessui/react']
    }
  };
});