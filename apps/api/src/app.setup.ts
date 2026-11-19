import type { INestApplication } from '@nestjs/common';

/**
 * Application-wide HTTP settings, shared by main.ts and the API tests
 * so that tests exercise exactly the production configuration.
 */
export function configureApp<T extends INestApplication>(app: T): T {
  // Every route is served under /api (the web app and the API share one origin, ADR 0013).
  app.setGlobalPrefix('api');

  // Close connections cleanly on SIGTERM/SIGINT (container stop, Ctrl+C).
  app.enableShutdownHooks();

  return app;
}
