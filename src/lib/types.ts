/**
 * Session data stored in localStorage
 */
export interface SessionData {
	auth_token: string;
	device_id: string;
	user_id: string;
	cert_base64: string;
	phone_number: string;
	private_keys: {
		login: string;
		signing: string;
	};
}

/**
 * JWT token payload
 */
export interface JWTPayload {
	jti?: string;
	sub?: string;
	iss?: string;
	exp?: number;
	iat?: number;
	deviceId?: string;
	publicKeyForLogin?: string;
	[key: string]: unknown;
}

/**
 * Door with operations
 */
export interface Door {
	publication_id: string;
	name: string;
	asset_id: string;
	asset_name: string;
	operations: Array<{
		id: string;
		name: string;
	}>;
	favorite: boolean;
}
