import { defineConfig, mergeConfig } from 'vitest/config';

import viteConfig from './vite.config.ts';

// Reuses the application's Vite config (React plugin) and adds the test settings.
export default mergeConfig(
  viteConfig,
  defineConfig({
    test: {
      include: ['src/**/*.spec.{ts,tsx}'],
      // Simulated browser: document, window, localStorage, navigator.
      environment: 'jsdom',
      setupFiles: ['./vitest.setup.ts'],
      restoreMocks: true,
    },
  }),
);
