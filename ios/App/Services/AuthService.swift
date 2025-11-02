import Foundation
import Security

/// Service for authentication operations
class AuthService {
    private let apiClient: APIClient
    private let keyStore: KeychainKeyStore

    init(apiClient: APIClient, keyStore: KeychainKeyStore) {
        self.apiClient = apiClient
        self.keyStore = keyStore
    }

    // MARK: - Authentication Flow

    /// Request SMS verification code
    func requestVerificationCode(phoneNumber: String) async throws -> String {
        let response = try await apiClient.requestVerification(msisdn: phoneNumber)
        return response.verificationCodeId
    }

    /// Submit verification code and get enrollment token
    func submitVerificationCode(code: String, verificationCodeId: String) async throws -> EnrollmentToken {
        let response = try await apiClient.submitVerificationCode(code: code, id: verificationCodeId)

        // Decode JWT to extract user/device info
        let payload = try JWT.decodePayload(response.token)
        let userId = payload.jti ?? payload.sub ?? ""
        let deviceId = payload.deviceId ?? ""

        return EnrollmentToken(
            token: response.token,
            recoveryKeyRequired: response.recoveryKeyRequired,
            userId: userId,
            deviceId: deviceId
        )
    }

    /// Validate recovery key
    func validateRecoveryKey(recoveryKey: String, enrollToken: String) async throws -> Bool {
        let response = try await apiClient.validateRecoveryKey(recoveryKey: recoveryKey, enrollToken: enrollToken)
        return response.valid
    }

    /// Enroll device and complete login flow
    /// Returns credentials that should be stored securely
    func enrollDeviceAndLogin(
        deviceName: String,
        recoveryKey: String?,
        enrollToken: EnrollmentToken
    ) async throws -> Credentials {
        // Generate key pairs on device
        let signingKeyPair = try CryptoKeys.generateKeyPair()
        let loginKeyPair = try CryptoKeys.generateKeyPair()

        // Create certificate signing requests
        let csrForSigning = try CSR.create(
            keyPair: signingKeyPair,
            userId: enrollToken.userId,
            deviceId: enrollToken.deviceId
        )
        let csrForLogin = try CSR.create(
            keyPair: loginKeyPair,
            userId: enrollToken.userId,
            deviceId: enrollToken.deviceId
        )

        // Enroll device with server
        let enrollRequest = EnrollRequest(
            deviceName: deviceName,
            recoveryKey: recoveryKey,
            csrForSigning: csrForSigning,
            csrForLogin: csrForLogin,
            appName: "Accessy-iOS"
        )

        let enrollResponse = try await apiClient.enrollDevice(
            request: enrollRequest,
            enrollToken: enrollToken.token
        )

        // Extract and decrypt device certificate
        guard let certBase64 = try CertificateExtractor.extractCertificate(
            from: enrollResponse.certificateForLogin,
            using: loginKeyPair.privateKey
        ) else {
            throw AuthServiceError.certificateExtractionFailed
        }

        // Create login proof and authenticate
        let loginProof = try Signing.createProof(certBase64: certBase64, privateKey: loginKeyPair.privateKey)
        let loginResponse = try await apiClient.login(loginProof: loginProof)

        // Update certificate from JWT if provided
        let jwtPayload = try JWT.decodePayload(loginResponse.authToken)
        let finalCert = jwtPayload.publicKeyForLogin ?? certBase64

        // Create credentials (keys will be stored separately)
        let credentials = Credentials(
            authToken: loginResponse.authToken,
            deviceId: enrollToken.deviceId,
            userId: enrollToken.userId,
            certBase64: finalCert
        )

        // Store private keys in Keychain using Apple's recommended approach
        try keyStore.saveKey(loginKeyPair.privateKey, identifier: credentials.loginKeyIdentifier)
        try keyStore.saveKey(signingKeyPair.privateKey, identifier: credentials.signingKeyIdentifier)

        return credentials
    }
}

// MARK: - Supporting Types

struct EnrollmentToken {
    let token: String
    let recoveryKeyRequired: Bool
    let userId: String
    let deviceId: String
}

enum AuthServiceError: Error {
    case certificateExtractionFailed
}
