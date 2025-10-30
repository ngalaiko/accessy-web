import { AccessyAPIClient } from './client';

/**
 * Server API client that calls the Accessy API directly
 * Used in SvelteKit server-side endpoints
 */
export const api = new AccessyAPIClient('https://api.accessy.se');
