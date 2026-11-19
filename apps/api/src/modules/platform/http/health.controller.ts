import { Controller, Get } from '@nestjs/common';

export interface HealthStatus {
  status: 'ok';
}

/**
 * Liveness probe used by the hosting platform and by local checks.
 * It does not touch the database: a readiness check will be added with Prisma (lot 2).
 */
@Controller('health')
export class HealthController {
  @Get()
  check(): HealthStatus {
    return { status: 'ok' };
  }
}
