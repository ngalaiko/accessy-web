import SwiftUI

struct DoorRow: View {
    let door: Door
    let isUnlocking: Bool
    let onTap: () -> Void

    var body: some View {
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
    }
}
