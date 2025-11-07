import SwiftUI

struct RecoveryStepView: View {
    @Binding var recoveryKey: String
    let isLoading: Bool
    let onContinue: () -> Void
    let onBack: () -> Void

    private func extractUUID(from text: String) -> String {
        let pattern = "[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}"
        if let range = text.range(of: pattern, options: .regularExpression) {
            return String(text[range])
        }
        return text
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Enter recovery key")
                .font(.headline)

            Text(
                """
                This device requires a recovery key. You can find it in the Accessy app → Settings → \
                Show recovery code
                """
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            TextField("Recovery Key", text: $recoveryKey)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .autocapitalization(.allCharacters)
                .onChange(of: recoveryKey) { _, newValue in
                    let extracted = extractUUID(from: newValue)
                    if extracted != newValue {
                        recoveryKey = extracted
                    }
                }

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
