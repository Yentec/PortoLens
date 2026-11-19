import { Module } from '@nestjs/common';

import { HealthController } from './http/health.controller.js';

/**
 * Cross-cutting building blocks (ADR 0011). For now: the health endpoint only.
 */
@Module({
  controllers: [HealthController],
})
export class PlatformModule {}
