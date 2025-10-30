import type { SessionData } from './types';
import type { EnrollTokenResponse, EnrollResponse, LoginResponse } from './api/types';
import { api } from './api/browser';
import { generateKeyPair, exportPrivateKeyPEM } from './crypto/keys';
import { createCSR } from './crypto/csr';
import { createProof } from './crypto/signing';
import { importPrivateKeyPEM } from './crypto/keys';
import { safeB64Decode, decryptCertificate } from './crypto/encryption';

/**
 * Client-side API service that handles all crypto operations
 * and communicates with server-side API proxies
 */

export async function requestVerificationCode(phoneNumber: string): Promise<string> {
	const data = await api.requestVerification({ msisdn: phoneNumber });
	return data.verificationCodeId;
}

export async function submitVerificationCode(
	code: string,
	verificationCodeId: string
): Promise<EnrollTokenResponse> {
	return await api.submitVerificationCode({ code, id: verificationCodeId });
}

export async function validateRecoveryKey(
	recoveryKey: string,
	enrollToken: string
): Promise<boolean> {
	const data = await api.validateRecoveryKey({ recoveryKey }, enrollToken);
	return data.valid;
}

export async function enrollDevice(
	deviceName: string,
	recoveryKey: string | null,
	enrollToken: string,
	userId: string,
	deviceId: string
): Promise<{
	certificates: EnrollResponse;
	privateKeys: { login: CryptoKey; signing: CryptoKey };
	certBase64: string | null;
}> {
	// Generate key pairs (on client!)
	const signingKeyPair = await generateKeyPair();
	const loginKeyPair = await generateKeyPair();

	// Create CSRs (on client!)
	const csrForSigning = await createCSR(signingKeyPair, userId, deviceId);
	const csrForLogin = await createCSR(loginKeyPair, userId, deviceId);

	// Send CSRs to server (keys never leave client)
	const data = await api.enrollDevice(
		{
			deviceName,
			recoveryKey,
			csrForSigning,
			csrForLogin,
			appName: 'Accessy-iOS'
		},
		enrollToken
	);

	// Try to extract device certificate
	let certBase64: string | null = null;
	try {
		const certParts = data.certificateForLogin.split('.');
		if (certParts.length >= 5) {
			// Part 2: Server's ephemeral public key
			const serverPubKeyB64 = certParts[2];
			const serverPubKeyDER = safeB64Decode(serverPubKeyB64);

			// Part 3: Contains encrypted data
			const certDataB64 = certParts[3];
			const certDataStr = new TextDecoder().decode(safeB64Decode(certDataB64));

			if (certDataStr.includes('.')) {
				const parts = certDataStr.split('.');
				if (parts.length === 3) {
					// Format: {iv}.{encrypted}.{hmac}
					const iv = safeB64Decode(parts[0]);
					const encrypted = safeB64Decode(parts[1]);
					const hmac = safeB64Decode(parts[2]);

					// Decrypt (on client!)
					certBase64 = await decryptCertificate(
						encrypted,
						iv,
						hmac,
						serverPubKeyDER,
						loginKeyPair.privateKey,
						parts[0],
						parts[1]
					);
				}
			}
		}
	} catch (e) {
		console.error('Could not extract device certificate:', e);
	}

	return {
		certificates: data,
		privateKeys: {
			login: loginKeyPair.privateKey,
			signing: signingKeyPair.privateKey
		},
		certBase64
	};
}

export async function login(
	enrollToken: string,
	certBase64: string | null,
	loginPrivateKey: CryptoKey
): Promise<LoginResponse> {
	if (!certBase64) {
		throw new Error('No certificate available for login');
	}

	// Create proof with decrypted certificate
	const loginProof = await createProof(certBase64, loginPrivateKey);
	return await api.login({ loginProof });
}

export async function getDoors(authToken: string) {
	return await api.getDoors(authToken);
}

export async function unlockDoor(
	operationId: string,
	authToken: string,
	certBase64: string,
	loginPrivateKey: CryptoKey
) {
	// Create proof (on client!)
	const proof = await createProof(certBase64, loginPrivateKey);
	return await api.unlockDoor({ operationId, proof }, authToken);
}

export async function saveSession(
	authToken: string,
	deviceId: string,
	userId: string,
	certBase64: string | null,
	certificates: EnrollResponse,
	phoneNumber: string,
	recoveryKey: string | null,
	privateKeys: { login: CryptoKey; signing: CryptoKey }
): Promise<SessionData> {
	const loginPEM = await exportPrivateKeyPEM(privateKeys.login);
	const signingPEM = await exportPrivateKeyPEM(privateKeys.signing);

	return {
		auth_token: authToken,
		device_id: deviceId,
		user_id: userId,
		cert_base64: certBase64 || '',
		certificates: {
			login: certificates.certificateForLogin,
			signing: certificates.certificateForSigning
		},
		phone_number: phoneNumber,
		recovery_key: recoveryKey || undefined,
		private_keys: {
			login: loginPEM,
			signing: signingPEM
		}
	};
}

export async function loadSessionKeys(sessionData: SessionData): Promise<{
	login: CryptoKey;
	signing: CryptoKey;
}> {
	return {
		login: await importPrivateKeyPEM(sessionData.private_keys.login),
		signing: await importPrivateKeyPEM(sessionData.private_keys.signing)
	};
}
