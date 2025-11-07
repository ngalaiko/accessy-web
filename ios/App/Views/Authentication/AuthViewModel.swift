import Combine
import Foundation

/// View model for authentication flow
/// Handles business logic and orchestrates between UI and AuthService
@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Published State

    @Published var isAuthenticated = false
    @Published var credentials: Credentials?

    // MARK: - Dependencies

    private let authService: AuthService
    private let credentialsStore: CredentialsService

    // MARK: - Initialization

    init(authService: AuthService, credentialsStore: CredentialsService) {
        self.authService = authService
        self.credentialsStore = credentialsStore
        loadCredentials()
    }

    // MARK: - Actions

    /// Load saved credentials from secure storage
    func loadCredentials() {
        do {
            credentials = try credentialsStore.load()
            isAuthenticated = true
        } catch {
            isAuthenticated = false
            credentials = nil
        }
    }

    /// Request SMS verification code
    func requestVerificationCode(phoneNumber: String) async throws -> String {
        try await authService.requestVerificationCode(phoneNumber: phoneNumber)
    }

    /// Submit verification code
    func submitVerificationCode(code: String, verificationCodeId: String) async throws -> EnrollmentToken {
        try await authService.submitVerificationCode(code: code, verificationCodeId: verificationCodeId)
    }

    /// Validate recovery key
    func validateRecoveryKey(recoveryKey: String, enrollToken: String) async throws -> Bool {
        try await authService.validateRecoveryKey(recoveryKey: recoveryKey, enrollToken: enrollToken)
    }

    /// Complete device enrollment and login
    func enrollDeviceAndLogin(
        phoneNumber _: String,
        deviceName: String,
        recoveryKey: String?,
        enrollToken: EnrollmentToken
    ) async throws {
        // Perform enrollment and login
        let creds = try await authService.enrollDeviceAndLogin(
            deviceName: deviceName,
            recoveryKey: recoveryKey,
            enrollToken: enrollToken
        )

        // Store credentials securely
        try credentialsStore.save(creds)
        credentials = creds
        isAuthenticated = true
    }

    /// Logout and clear all data
    func logout() {
        try? credentialsStore.delete()
        credentials = nil
        isAuthenticated = false
    }
}
