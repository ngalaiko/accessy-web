import SwiftUI

struct PhoneStepView: View {
    @Binding var phoneNumber: String
    let isLoading: Bool
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Enter your phone number")
                .font(.headline)

            Text("Use the phone number registered with the Accessy app")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField("Phone Number", text: $phoneNumber)
                .textFieldStyle(.roundedBorder)
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)
                .autocorrectionDisabled()
                .onAppear {
                    if phoneNumber.isEmpty {
                        phoneNumber = "+"
                    }
                }
                .onChange(of: phoneNumber) { _, newValue in
                    // Ensure + prefix for E.164 format
                    if !newValue.isEmpty && !newValue.hasPrefix("+") {
                        phoneNumber = "+" + newValue.filter { $0.isNumber }
                    } else {
                        let filtered = newValue.prefix(1) + newValue.dropFirst().filter { $0.isNumber }
                        if filtered != newValue {
                            phoneNumber = String(filtered)
                        }
                    }
                    // Limit to E.164 max length: +15 digits = 16 chars
                    if phoneNumber.count > 16 {
                        phoneNumber = String(phoneNumber.prefix(16))
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
            .disabled(isLoading || phoneNumber.count < 8)
        }
    }
}
