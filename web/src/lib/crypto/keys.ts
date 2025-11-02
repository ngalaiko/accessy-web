/**
 * EC P-256 (secp256r1) key generation
 */
export async function generateKeyPair(): Promise<CryptoKeyPair> {
	return await crypto.subtle.generateKey(
		{
			name: 'ECDSA',
			namedCurve: 'P-256'
		},
		true, // extractable
		['sign', 'verify']
	);
}

/**
 * Export private key to PEM format
 */
export async function exportPrivateKeyPEM(key: CryptoKey): Promise<string> {
	const exported = await crypto.subtle.exportKey('pkcs8', key);
	const exportedAsBase64 = btoa(String.fromCharCode(...new Uint8Array(exported)));
	return `-----BEGIN PRIVATE KEY-----\n${exportedAsBase64.match(/.{1,64}/g)?.join('\n')}\n-----END PRIVATE KEY-----`;
}

/**
 * Import private key from PEM format
 */
export async function importPrivateKeyPEM(pem: string): Promise<CryptoKey> {
	const pemContents = pem
		.replace(/-----BEGIN PRIVATE KEY-----/, '')
		.replace(/-----END PRIVATE KEY-----/, '')
		.replace(/\s/g, '');
	const binaryDer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

	return await crypto.subtle.importKey(
		'pkcs8',
		binaryDer,
		{
			name: 'ECDSA',
			namedCurve: 'P-256'
		},
		true,
		['sign']
	);
}

/**
 * Export public key to DER format
 */
export async function exportPublicKeyDER(key: CryptoKey): Promise<Uint8Array> {
	const exported = await crypto.subtle.exportKey('spki', key);
	return new Uint8Array(exported);
}
