import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig(({ mode }) => {
  if (mode === 'production' && !process.env.VITE_SITE_URL) {
    throw new Error('VITE_SITE_URL is not defined. Please set it in your .env.production file.');
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