/**
 * ECDH key agreement and shared secret derivation
 */

/**
 * Perform ECDH key exchange and derive shared secret
 * Returns SHA-512 hash of shared secret (64 bytes)
 */
export async function deriveSharedSecret(
	clientPrivateKey: CryptoKey,
	serverPublicKeyDER: Uint8Array
): Promise<Uint8Array> {
	// Import server's public key for ECDH
	// IMPORTANT: Must create a new ArrayBuffer, not use .buffer (which might be a view)
	const serverPublicKeyBuffer = serverPublicKeyDER.slice(0).buffer;
	const serverPublicKey = await crypto.subtle.importKey(
		'spki',
		serverPublicKeyBuffer,
		{
			name: 'ECDH',
			namedCurve: 'P-256'
		},
		false,
		[]
	);

	// Re-import client private key as ECDH key (it was created as ECDSA)
	const clientPrivateKeyJwk = await crypto.subtle.exportKey('jwk', clientPrivateKey);
	// Remove key_ops field to avoid conflicts when changing algorithm
	delete clientPrivateKeyJwk.key_ops;
	// Also remove alg field if present
	delete clientPrivateKeyJwk.alg;
	const ecdhPrivateKey = await crypto.subtle.importKey(
		'jwk',
		clientPrivateKeyJwk,
		{
			name: 'ECDH',
			namedCurve: 'P-256'
		},
		false,
		['deriveBits']
	);

	// Perform ECDH
	const sharedSecret = await crypto.subtle.deriveBits(
		{
			name: 'ECDH',
			public: serverPublicKey
		},
		ecdhPrivateKey,
		256 // bits
	);

	// Hash with SHA-512
	const derivedKey = await crypto.subtle.digest('SHA-512', sharedSecret);

	return new Uint8Array(derivedKey);
}
