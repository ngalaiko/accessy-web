import SwiftUI

/// Banner displayed when app is in demo mode for App Store review
struct DemoModeBanner: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 16))

                Text("App Review Demo Mode")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Spacer()

                Text("Full functionality available")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.orange)
        }
    }
}

#Preview {
    DemoModeBanner()
}
