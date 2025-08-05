import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig(({ mode }) => {
  // Set default VITE_SITE_URL if not provided
  if (mode === 'production' && !process.env.VITE_SITE_URL) {
    process.env.VITE_SITE_URL = 'https://winterhill-cobros-oeob29ghh-eduardomeiks-projects.vercel.app';
    console.warn('⚠️  VITE_SITE_URL not set, using default. Please set it in .env.production for production deployment.');
  }

  return {
    plugins: [react()],
    build: {
      outDir: 'dist',
      sourcemap: true,
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