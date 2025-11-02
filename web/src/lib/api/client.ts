import type {
	VerifyRequest,
	VerifyResponse,
	EnrollTokenRequest,
	EnrollTokenResponse,
	ValidateRecoveryRequest,
	ValidateRecoveryResponse,
	EnrollRequest,
	EnrollResponse,
	LoginRequest,
	LoginResponse,
	DoorsResponse,
	UnlockRequest,
	UnlockResponse
} from './types';

const HEADERS = {
	Host: 'api.accessy.se',
	accept: 'application/vnd.axessions.v1+json',
	'x-axs-plan': 'accessy',
	'content-type': 'application/json'
};

export class AccessyAPIClient {
	constructor(private baseUrl: string) {}

	async requestVerification(request: VerifyRequest): Promise<VerifyResponse> {
		const response = await fetch(`${this.baseUrl}/auth/recover`, {
			method: 'POST',
			headers: HEADERS,
			body: JSON.stringify({ msisdn: request.msisdn })
		});

		if (!response.ok) {
			throw new Error(`Failed to request verification: ${response.statusText}`);
		}

		return await response.json();
	}

	async submitVerificationCode(request: EnrollTokenRequest): Promise<EnrollTokenResponse> {
		const response = await fetch(`${this.baseUrl}/auth/mobile-device/enroll/token`, {
			method: 'POST',
			headers: HEADERS,
			body: JSON.stringify({ code: request.code, id: request.id.toUpperCase() })
		});

		if (!response.ok) {
			throw new Error(`Failed to submit verification code: ${response.statusText}`);
		}

		return await response.json();
	}

	async validateRecoveryKey(
		request: ValidateRecoveryRequest,
		enrollToken: string
	): Promise<ValidateRecoveryResponse> {
		const response = await fetch(`${this.baseUrl}/auth/validate-recovery-key`, {
			method: 'POST',
			headers: {
				...HEADERS,
				authorization: `Bearer ${enrollToken}`
			},
			body: JSON.stringify({ recoveryKey: request.recoveryKey })
		});

		if (!response.ok) {
			throw new Error(`Failed to validate recovery key: ${response.statusText}`);
		}

		return await response.json();
	}

	async enrollDevice(request: EnrollRequest, enrollToken: string): Promise<EnrollResponse> {
		const response = await fetch(`${this.baseUrl}/auth/mobile-device/enroll`, {
			method: 'POST',
			headers: {
				...HEADERS,
				authorization: `Bearer ${enrollToken}`,
				accept: 'application/vnd.axessions.v2+json'
			},
			body: JSON.stringify({
				deviceName: request.deviceName,
				recoveryKey: request.recoveryKey,
				csrForSigning: request.csrForSigning,
				csrForLogin: request.csrForLogin,
				appName: request.appName
			})
		});

		if (!response.ok) {
			throw new Error(`Failed to enroll device: ${response.statusText}`);
		}

		return await response.json();
	}

	async login(request: LoginRequest): Promise<LoginResponse> {
		const response = await fetch(`${this.baseUrl}/auth/mobile-device/login`, {
			method: 'POST',
			headers: {
				...HEADERS,
				'content-type': 'text/plain'
			},
			body: request.loginProof
		});

		if (!response.ok) {
			throw new Error(`Failed to login: ${response.statusText}`);
		}

		return await response.json();
	}

	async getDoors(authToken: string): Promise<DoorsResponse> {
		const response = await fetch(`${this.baseUrl}/org/client-context/mobile`, {
			method: 'GET',
			headers: {
				...HEADERS,
				accept: 'application/vnd.axessions.v2+json',
				authorization: `Bearer ${authToken}`
			}
		});

		if (!response.ok) {
			throw new Error(`Failed to get doors: ${response.statusText}`);
		}

		return await response.json();
	}

	async unlockDoor(request: UnlockRequest, authToken: string): Promise<UnlockResponse> {
		const response = await fetch(
			`${this.baseUrl}/asset/asset-operation/${request.operationId}/invoke`,
			{
				method: 'PUT',
				headers: {
					...HEADERS,
					authorization: `Bearer ${authToken}`,
					'x-axs-proof': request.proof
				},
				body: JSON.stringify({})
			}
		);

		if (!response.ok) {
			throw new Error(`Failed to unlock door: ${response.statusText}`);
		}

		if (response.headers.get('content-length') === '0' || !response.body) {
			return { status: 'success' };
		}

		return await response.json();
	}
}
