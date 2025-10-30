import type { JWTPayload } from '../types';

/**
 * Decode JWT token payload without verification
 */
export function decodeJWTPayload(token: string): JWTPayload {
	const parts = token.split('.');
	if (parts.length !== 3) {
		throw new Error('Invalid JWT format');
	}

	// Add padding if needed
	let payloadB64 = parts[1];
	const padding = 4 - (payloadB64.length % 4);
	if (padding !== 4) {
		payloadB64 += '='.repeat(padding);
	}

	const payloadJson = atob(payloadB64);
	return JSON.parse(payloadJson);
}
