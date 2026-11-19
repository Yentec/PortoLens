import { screen } from '@testing-library/react';
import { describe, expect, it, vi } from 'vitest';

import { renderWithProviders } from '../../test/render-with-providers';
import { HealthStatus } from './health-status';

describe('HealthStatus', () => {
  it('shows a pending message, then confirms the API is up', async () => {
    const fetchMock = vi
      .spyOn(globalThis, 'fetch')
      .mockResolvedValue(Response.json({ status: 'ok' }, { status: 200 }));

    renderWithProviders(<HealthStatus />);

    expect(screen.getByText('Checking the API…')).toBeDefined();
    expect(await screen.findByText('The API is up and running.')).toBeDefined();
    // Relative URL (same origin, ADR 0013) and a cancellation signal from TanStack Query.
    const [url, init] = fetchMock.mock.calls[0] ?? [];
    expect(url).toBe('/api/health');
    expect(init?.signal).toBeInstanceOf(AbortSignal);
  });

  it('shows an alert when the API answers with an error status', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(new Response(null, { status: 503 }));

    renderWithProviders(<HealthStatus />);

    expect((await screen.findByRole('alert')).textContent).toBe('The API cannot be reached.');
  });

  it('shows an alert when the network fails', async () => {
    vi.spyOn(globalThis, 'fetch').mockRejectedValue(new TypeError('Failed to fetch'));

    renderWithProviders(<HealthStatus />);

    expect((await screen.findByRole('alert')).textContent).toBe('The API cannot be reached.');
  });
});
