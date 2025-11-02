import SwiftUI

struct RecoveryStepView: View {
    @Binding var recoveryKey: String
    let isLoading: Bool
    let onContinue: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Enter recovery key")
                .font(.headline)

            Text("This device requires a recovery key")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            SecureField("Recovery Key", text: $recoveryKey)
                .textFieldStyle(.roundedBorder)
                .textContentType(.password)
                .autocorrectionDisabled()
                .autocapitalization(.none)

            Button(action: onContinue) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading || recoveryKey.isEmpty)

            Button("Back", action: onBack)
                .disabled(isLoading)
        }
    }
}
