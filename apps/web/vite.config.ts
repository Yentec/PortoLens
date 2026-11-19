import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

const API_ORIGIN = 'http://localhost:3000';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    strictPort: true,
    // Same-origin in development (ADR 0013): the browser only talks to Vite,
    // which forwards /api/* to the NestJS API. No CORS, cookies work as in production.
    proxy: {
      '/api': { target: API_ORIGIN, changeOrigin: false },
    },
  },
});
