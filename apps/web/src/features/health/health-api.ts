/**
 * Temporary local type: it moves to @portolens/contracts (Zod schema) with the first real endpoint.
 */
export interface HealthResponse {
  status: 'ok';
}

export async function fetchHealth(signal: AbortSignal): Promise<HealthResponse> {
  const response = await fetch('/api/health', { signal });
  if (!response.ok) {
    throw new Error(`Health check failed with HTTP ${response.status}`);
  }
  return (await response.json()) as HealthResponse;
}
