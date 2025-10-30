import { AccessyAPIClient } from './client';

/**
 * Browser API client that uses the SvelteKit proxy
 * This routes all requests through /api/accessy/* endpoints
 * to bypass CORS restrictions
 */
export const api = new AccessyAPIClient('/api/accessy');
