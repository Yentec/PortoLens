import { Injectable } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { describe, expect, it } from 'vitest';

/**
 * Guards the test toolchain: NestJS resolves constructor dependencies from the
 * decorator metadata emitted by the transformer (see vitest.config.ts). If that
 * metadata ever stops being emitted, this test fails instead of every service
 * silently receiving `undefined`.
 */
@Injectable()
class Clock {
  now(): Date {
    return new Date(0);
  }
}

@Injectable()
class UsesClock {
  constructor(readonly clock: Clock) {}
}

describe('toolchain', () => {
  it('injects constructor dependencies by type', async () => {
    const moduleRef = await Test.createTestingModule({ providers: [Clock, UsesClock] }).compile();

    const consumer = moduleRef.get(UsesClock);

    expect(consumer.clock).toBeInstanceOf(Clock);
  });
});
