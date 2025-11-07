import CoreLocation
import SwiftUI

struct DoorRow: View {
    let door: Door
    let isUnlocking: Bool
    let distance: CLLocationDistance?
    let onTap: () -> Void
    let onFavoriteTap: () -> Void

    var body: some View {
        HStack {
            Button(action: onTap) {
                HStack {
                    Text(door.name)
                    Spacer()
                    if isUnlocking {
                        ProgressView()
                    }
                }
            }
            .disabled(isUnlocking || door.operations.isEmpty)

            Button(action: onFavoriteTap) {
                Image(systemName: door.favorite ? "star.fill" : "star")
                    .foregroundColor(door.favorite ? .yellow : .gray)
            }
            .buttonStyle(.borderless)
        }
    }

    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
}
