import { deriveSharedSecret } from './ecdh';

/**
 * Decrypt certificate using AES-256-CBC + HMAC-SHA256 with ECDH-derived key
 *
 * Based on Android app decompilation:
 * 1. ECDH shared secret
 * 2. SHA-512 hash of shared secret → 64 bytes
 * 3. Split: first 32 bytes = AES key, last 32 bytes = HMAC key
 * 4. Verify HMAC-SHA256, then decrypt with AES-256-CBC
 */
export async function decryptCertificate(
	encryptedCert: Uint8Array,
	iv: Uint8Array,
	hmacTag: Uint8Array,
	serverEphemeralPublicKeyDER: Uint8Array,
	clientPrivateKey: CryptoKey,
	ivB64Original: string,
	ciphertextB64Original: string
): Promise<string> {
	// Step 1-3: Derive shared secret and hash with SHA-512
	const derivedKey = await deriveSharedSecret(clientPrivateKey, serverEphemeralPublicKeyDER);

	// Step 4: Split key
	const aesKey = derivedKey.slice(0, 32); // First 32 bytes for AES-256
	const hmacKey = derivedKey.slice(32); // Last 32 bytes for HMAC-SHA256

	// Step 5: Verify HMAC over original base64 strings
	const dataToVerify = new TextEncoder().encode(`${ivB64Original}.${ciphertextB64Original}`);
	const hmacKeyImported = await crypto.subtle.importKey(
		'raw',
		hmacKey,
		{ name: 'HMAC', hash: 'SHA-256' },
		false,
		['sign']
	);

	const expectedHmac = await crypto.subtle.sign('HMAC', hmacKeyImported, dataToVerify);

	if (!constantTimeEqual(new Uint8Array(expectedHmac), hmacTag)) {
		throw new Error('HMAC verification failed - certificate may be tampered');
	}

	// Step 6: Decrypt with AES-256-CBC
	const aesKeyImported = await crypto.subtle.importKey('raw', aesKey, { name: 'AES-CBC' }, false, [
		'decrypt'
	]);

	const plaintext = await crypto.subtle.decrypt(
		{ name: 'AES-CBC', iv: iv.buffer as ArrayBuffer },
		aesKeyImported,
		encryptedCert.buffer as ArrayBuffer
	);

	// Step 7: Convert to string (might be ASCII text or binary DER)
	const plaintextBytes = new Uint8Array(plaintext);

	try {
		// Try to decode as ASCII text first
		const plaintextStr = new TextDecoder('ascii').decode(plaintextBytes);
		return plaintextStr;
	} catch {
		// If not ASCII, might be raw DER certificate
		if (plaintextBytes[0] === 0x30) {
			// ASN.1 SEQUENCE tag for X.509
			return btoa(String.fromCharCode(...plaintextBytes));
		}
		// Unknown format, return as base64
		return btoa(String.fromCharCode(...plaintextBytes));
	}
}

/**
 * Constant-time comparison to prevent timing attacks
 */
function constantTimeEqual(a: Uint8Array, b: Uint8Array): boolean {
	if (a.length !== b.length) {
		return false;
	}
	let result = 0;
	for (let i = 0; i < a.length; i++) {
		result |= a[i] ^ b[i];
	}
	return result === 0;
}

/**
 * Helper: Decode URL-safe base64 with proper padding
 */
export function safeB64Decode(s: string): Uint8Array {
	// Convert URL-safe to standard base64
	s = s.replace(/-/g, '+').replace(/_/g, '/');
	const padding = 4 - (s.length % 4);
	if (padding !== 4) {
		s = s + '='.repeat(padding);
	}
	return Uint8Array.from(atob(s), (c) => c.charCodeAt(0));
}
