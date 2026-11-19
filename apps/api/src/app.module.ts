import { Module } from '@nestjs/common';

import { PlatformModule } from './modules/platform/platform.module.js';

/**
 * Root module: only composes business modules (ADR 0011). It holds no logic of its own.
 */
@Module({
  imports: [PlatformModule],
})
export class AppModule {}
