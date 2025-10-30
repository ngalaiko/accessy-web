/**
 * Convert IEEE P1363 signature to DER format
 * Web Crypto returns P1363 (r||s), but we need DER (ASN.1)
 */
function p1363ToDer(p1363Sig: Uint8Array): Uint8Array {
	// P-256 signature: 64 bytes (32 bytes r + 32 bytes s)
	const r = p1363Sig.slice(0, 32);
	const s = p1363Sig.slice(32, 64);

	// Helper to encode integer in DER format
	const encodeInteger = (int: Uint8Array): Uint8Array => {
		// If high bit is set, prepend 0x00 to indicate positive number
		if (int[0] >= 0x80) {
			const padded = new Uint8Array(int.length + 1);
			padded[0] = 0x00;
			padded.set(int, 1);
			return padded;
		}
		// Remove leading zeros (but keep at least one byte)
		let start = 0;
		while (start < int.length - 1 && int[start] === 0x00 && int[start + 1] < 0x80) {
			start++;
		}
		return int.slice(start);
	};

	const rEncoded = encodeInteger(r);
	const sEncoded = encodeInteger(s);

	// Build DER sequence: 0x30 [length] 0x02 [r length] [r] 0x02 [s length] [s]
	const derLength = 2 + rEncoded.length + 2 + sEncoded.length;
	const der = new Uint8Array(2 + derLength);

	let offset = 0;
	der[offset++] = 0x30; // SEQUENCE tag
	der[offset++] = derLength;

	der[offset++] = 0x02; // INTEGER tag for r
	der[offset++] = rEncoded.length;
	der.set(rEncoded, offset);
	offset += rEncoded.length;

	der[offset++] = 0x02; // INTEGER tag for s
	der[offset++] = sEncoded.length;
	der.set(sEncoded, offset);

	return der;
}

/**
 * Sign data with ECDSA-SHA256
 */
export async function signData(data: string, privateKey: CryptoKey): Promise<string> {
	const encoder = new TextEncoder();
	const dataBytes = encoder.encode(data);

	const signature = await crypto.subtle.sign(
		{
			name: 'ECDSA',
			hash: { name: 'SHA-256' }
		},
		privateKey,
		dataBytes
	);

	// Web Crypto returns IEEE P1363 format, convert to DER
	const p1363Sig = new Uint8Array(signature);
	const derSig = p1363ToDer(p1363Sig);

	// Convert to base64
	return btoa(String.fromCharCode(...derSig));
}

/**
 * Create authentication proof in format:
 * {header}.{certificate}.{payload}.{signature}
 */
export async function createProof(certBase64: string, privateKey: CryptoKey): Promise<string> {
	// Step 1: Generate header
	const header = base64UrlEncode(new TextEncoder().encode('axs.1.4'));

	// Step 2: Encode certificate string
	const certificate = base64UrlEncode(new TextEncoder().encode(certBase64));

	// Step 3: Generate payload - timestamp rounded to nearest 5 seconds
	const currentTime = Math.floor(Date.now() / 1000);
	const roundedTime = currentTime - (currentTime % 5);
	const timestampStr = String(roundedTime);
	const payload = base64UrlEncode(new TextEncoder().encode(timestampStr));

	// Step 4: Sign the data (header.certificate.payload)
	const dataToSign = `${header}.${certificate}.${payload}`;
	const signatureB64 = await signData(dataToSign, privateKey);
	// Convert standard base64 to URL-safe (just string replacement, don't decode/re-encode!)
	const signature = signatureB64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');

	// Step 5: Build final proof
	return `${header}.${certificate}.${payload}.${signature}`;
}

/**
 * Helper: Convert standard base64 to URL-safe base64 without padding
 */
function base64UrlEncode(bytes: Uint8Array): string {
	const base64 = btoa(String.fromCharCode(...bytes));
	return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}
