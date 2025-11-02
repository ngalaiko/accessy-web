import CoreLocation
import SwiftUI

struct DoorRow: View {
    let door: Door
    let isUnlocking: Bool
    let distance: CLLocationDistance?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(door.name)
                Spacer()
                if let distance = distance {
                    Text(formatDistance(distance))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                if isUnlocking {
                    ProgressView()
                }
            }
        }
        .disabled(isUnlocking || door.operations.isEmpty)
    }

    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
}
