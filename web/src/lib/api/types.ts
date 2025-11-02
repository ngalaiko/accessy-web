export interface VerifyRequest {
	msisdn: string;
}

export interface VerifyResponse {
	verificationCodeId: string;
}

export interface EnrollTokenRequest {
	code: string;
	id: string;
}

export interface EnrollTokenResponse {
	token: string;
	recoveryKeyRequired: boolean;
}

export interface ValidateRecoveryRequest {
	recoveryKey: string;
}

export interface ValidateRecoveryResponse {
	valid: boolean;
}

export interface EnrollRequest {
	deviceName: string;
	recoveryKey: string | null;
	csrForSigning: string;
	csrForLogin: string;
	appName: string;
}

export interface EnrollResponse {
	certificateForLogin: string;
	certificateForSigning: string;
}

export interface LoginRequest {
	loginProof: string;
}

export interface LoginResponse {
	auth_token: string;
}

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

export interface DoorsResponse {
	mostInvokedPublicationsList: Array<Door>;
}

export interface UnlockRequest {
	operationId: string;
	proof: string;
}

export interface UnlockResponse {
	status?: string;
}
