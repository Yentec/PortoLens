import { defineConfig } from 'vitest/config';

export default defineConfig({
  // NestJS resolves constructor dependencies from decorator metadata.
  // Vite's built-in Oxc transformer emits it when configured explicitly (no extra plugin needed).
  oxc: {
    decorator: {
      legacy: true,
      emitDecoratorMetadata: true,
    },
  },
  test: {
    include: ['src/**/*.spec.ts', 'test/**/*.spec.ts'],
    environment: 'node',
    restoreMocks: true,
  },
});
