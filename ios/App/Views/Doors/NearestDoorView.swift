import CoreLocation
import SwiftUI

/// View that displays a button to open the nearest door
struct NearestDoorView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var nearestDoorManager: NearestDoorManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isUnlocking = false

    var body: some View {
        VStack(spacing: 20) {
            if nearestDoorManager.isLoadingDoors && nearestDoorManager.doors.isEmpty {
                ProgressView()
            } else if let nearest = nearestDoorManager.nearestDoor {
                VStack(spacing: 16) {
                    // Door info
                    Text(nearest.name)
                        .font(.title2)
                        .fontWeight(.semibold)

                    // Open button
                    Button(action: handleUnlock) {
                        HStack {
                            if isUnlocking {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Open Door")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isUnlocking || nearest.operations.isEmpty)
                    .padding(.horizontal)
                }
            } else {
                emptyStateView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Error", isPresented: .constant(nearestDoorManager.errorMessage != nil)) {
            Button("OK") {
                nearestDoorManager.errorMessage = nil
            }
        } message: {
            if let error = nearestDoorManager.errorMessage {
                Text(error)
            }
        }
        .task {
            await loadDoors()
        }
        .onChange(of: locationManager.currentLocation) { _, _ in
            nearestDoorManager.updateNearestDoor(currentLocation: locationManager.currentLocation)
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        let noLocation = locationManager.currentLocation == nil
        let imageName = noLocation ? "location.slash" : "exclamationmark.triangle"
        let title = noLocation ? "Location unavailable" : "No nearby doors found"
        let subtitle = noLocation
            ? "Enable location services to find nearby doors"
            : "Make sure doors have location information"

        return VStack(spacing: 12) {
            Image(systemName: imageName)
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Helper Methods

    private func loadDoors() async {
        guard let credentials = authViewModel.credentials else { return }
        await nearestDoorManager.loadDoors(credentials: credentials)
        nearestDoorManager.updateNearestDoor(currentLocation: locationManager.currentLocation)
    }

    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return String(format: "%.0f m away", distance)
        } else {
            return String(format: "%.1f km away", distance / 1000)
        }
    }

    private func handleUnlock() {
        guard let credentials = authViewModel.credentials else { return }
        isUnlocking = true

        Task {
            do {
                try await nearestDoorManager.unlockNearestDoor(credentials: credentials)
                // Success - maybe show a success indicator briefly
                try? await Task.sleep(nanoseconds: 500_000_000)
            } catch {
                nearestDoorManager.errorMessage = error.localizedDescription
            }
            isUnlocking = false
        }
    }
}
