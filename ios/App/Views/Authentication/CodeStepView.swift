import SwiftUI

struct CodeStepView: View {
    let phoneNumber: String
    @Binding var verificationCode: String
    let isLoading: Bool
    let onVerify: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Enter verification code")
                .font(.headline)

            Text("Sent to \(phoneNumber)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("000000", text: $verificationCode)
                .textFieldStyle(.roundedBorder)
                .textContentType(.oneTimeCode)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.title2)
                .autocorrectionDisabled()
                .onChange(of: verificationCode) { _, newValue in
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered != newValue {
                        verificationCode = filtered
                    }
                    if verificationCode.count > 6 {
                        verificationCode = String(verificationCode.prefix(6))
                    }
                    // Auto-submit when 6 digits entered
                    if verificationCode.count == 6 && !isLoading {
                        onVerify()
                    }
                }

            Button(action: onVerify) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Verify")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading || verificationCode.count != 6)

            Button("Back", action: onBack)
                .disabled(isLoading)
        }
    }
}
