import SwiftUI
import UIKit

/// Simple authentication flow with native iOS components
struct LoginView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var state = LoginState()

    struct LoginState {
        var phoneNumber = ""
        var verificationCode = ""
        var recoveryKey = ""
        var deviceName = UIDevice.current.name
        var verificationCodeId = ""
        var enrollToken: EnrollmentToken?
        var isLoading = false
        var errorMessage: String?
        var step: Step = .phone

        enum Step {
            case phone
            case code
            case recovery
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                // Main content
                VStack(spacing: 16) {
                    switch state.step {
                    case .phone:
                        phoneStep
                    case .code:
                        codeStep
                    case .recovery:
                        recoveryStep
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: .constant(state.errorMessage != nil)) {
                Button("OK") { state.errorMessage = nil }
            } message: {
                if let error = state.errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Step Views

    private var phoneStep: some View {
        PhoneStepView(
            phoneNumber: $state.phoneNumber,
            isLoading: state.isLoading,
            onContinue: requestCode
        )
    }

    private var codeStep: some View {
        CodeStepView(
            phoneNumber: state.phoneNumber,
            verificationCode: $state.verificationCode,
            isLoading: state.isLoading,
            onVerify: submitCode,
            onBack: {
                state.step = .phone
                state.verificationCode = ""
            }
        )
    }

    private var recoveryStep: some View {
        RecoveryStepView(
            recoveryKey: $state.recoveryKey,
            isLoading: state.isLoading,
            onContinue: validateRecoveryAndEnroll,
            onBack: {
                state.step = .code
                state.recoveryKey = ""
            }
        )
    }

    // MARK: - Actions

    private func requestCode() {
        state.isLoading = true
        state.errorMessage = nil

        Task {
            do {
                state.verificationCodeId = try await viewModel.requestVerificationCode(phoneNumber: state.phoneNumber)
                state.step = .code
            } catch {
                state.errorMessage = error.localizedDescription
            }
            state.isLoading = false
        }
    }

    private func submitCode() {
        state.isLoading = true
        state.errorMessage = nil

        Task {
            do {
                let token = try await viewModel.submitVerificationCode(
                    code: state.verificationCode,
                    verificationCodeId: state.verificationCodeId
                )
                state.enrollToken = token

                if token.recoveryKeyRequired {
                    state.step = .recovery
                    state.isLoading = false
                } else {
                    await enrollDevice()
                }
            } catch {
                state.errorMessage = error.localizedDescription
                state.isLoading = false
            }
        }
    }

    private func validateRecoveryAndEnroll() {
        guard let token = state.enrollToken else { return }

        state.isLoading = true
        state.errorMessage = nil

        Task {
            do {
                let valid = try await viewModel.validateRecoveryKey(
                    recoveryKey: state.recoveryKey,
                    enrollToken: token.token
                )
                if !valid {
                    throw NSError(
                        domain: "AuthError",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid recovery key"]
                    )
                }
                await enrollDevice()
            } catch {
                state.errorMessage = error.localizedDescription
                state.isLoading = false
            }
        }
    }

    private func enrollDevice() async {
        guard let token = state.enrollToken else { return }

        do {
            try await viewModel.enrollDeviceAndLogin(
                phoneNumber: state.phoneNumber,
                deviceName: state.deviceName,
                recoveryKey: state.recoveryKey.isEmpty ? nil : state.recoveryKey,
                enrollToken: token
            )
        } catch {
            state.errorMessage = error.localizedDescription
            state.step = .phone
            state.isLoading = false
        }
    }
}

#Preview {
    let keyStore = KeychainKeyStore()
    let credentialsStore = CredentialsStore(keyStore: keyStore)
    let apiClient = APIClient()
    let authService = AuthService(apiClient: apiClient, keyStore: keyStore)
    let authViewModel = AuthViewModel(authService: authService, credentialsStore: credentialsStore)

    LoginView()
        .environmentObject(authViewModel)
}
