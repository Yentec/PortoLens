import 'reflect-metadata';

import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';

import { AppModule } from './app.module.js';
import { configureApp } from './app.setup.js';

const DEFAULT_PORT = 3000;

async function bootstrap(): Promise<void> {
  const app = configureApp(await NestFactory.create(AppModule));

  const port = Number(process.env['PORT'] ?? DEFAULT_PORT);
  await app.listen(port);

  Logger.log(`API listening on http://localhost:${port}/api`, 'Bootstrap');
}

await bootstrap();
