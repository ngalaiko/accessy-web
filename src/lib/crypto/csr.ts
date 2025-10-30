import * as x509 from '@peculiar/x509';

/**
 * Create a Certificate Signing Request in Accessy format
 * Returns: {base64("axs.1.0")}.{base64(base64(csr_der))}
 */
export async function createCSR(
	keyPair: CryptoKeyPair,
	userId: string,
	deviceId: string
): Promise<string> {
	// Use @peculiar/x509 to create CSR
	const csr = await x509.Pkcs10CertificateRequestGenerator.create({
		name: `O=${userId}, CN=${deviceId}`,
		keys: keyPair,
		signingAlgorithm: { name: 'ECDSA', hash: 'SHA-256' }
	});

	// Serialize to DER
	const csrDer = csr.rawData;

	// First base64 encoding
	const csrB64Inner = btoa(String.fromCharCode(...new Uint8Array(csrDer)));

	// Second base64 encoding
	const csrB64Outer = btoa(csrB64Inner);

	// Encode version header as base64 (remove padding)
	const versionB64 = btoa('axs.1.0').replace(/=/g, '');

	// Remove padding from outer base64 too
	const csrB64OuterNoPadding = csrB64Outer.replace(/=/g, '');

	// Format: {base64(version)}.{base64(base64(csr))} - no padding!
	return `${versionB64}.${csrB64OuterNoPadding}`;
}
