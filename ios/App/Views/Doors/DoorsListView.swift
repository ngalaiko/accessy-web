import CoreLocation
import SwiftUI
import UIKit

/// Pure UI view for doors list
/// All business logic is in DoorsViewModel
struct DoorsListView: View {
    @Environment(\.doorsService)
    var doorsService

    @EnvironmentObject var locationService: LocationService
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    @State private var doors: [Door] = []
    @State private var isLoading = false
    @State private var unlockingDoorId: String?
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Demo mode banner
                if authViewModel.credentials?.isDemoMode == true {
                    DemoModeBanner()
                }

                Group {
                    if locationService.isAuthorized {
                        TabView(selection: $selectedTab) {
                            // Nearest door (first tab, default)
                            nearestDoor
                                .tabItem {
                                    Label("Nearest", systemImage: "location.fill")
                                }
                                .tag(0)

                            // List of all doors
                            doorsList
                                .tabItem {
                                    Label("All Doors", systemImage: "list.bullet")
                                }
                                .tag(1)
                        }
                    } else {
                        // Show only doors list without tabs when location is not authorized
                        doorsList
                    }
                }
            }
            .navigationTitle("Doors")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Logout") {
                        authViewModel.logout()
                    }
                }
            }
        }
        .task {
            await loadDoorsIfNeeded()
        }
    }

    // MARK: - Subviews

    private var doorsList: some View {
        List {
            if isLoading && doors.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if doors.isEmpty {
                Text("No doors available")
                    .foregroundColor(.secondary)
            } else {
                ForEach(doors) { door in
                    DoorRow(
                        door: door,
                        isUnlocking: unlockingDoorId == door.id,
                        distance: calculateDistance(to: door),
                        onTap: { handleUnlock(door) }
                    )
                }
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .refreshable {
            await loadDoorsIfNeeded()
        }
    }

    private var nearestDoor: some View {
        NearestDoorView()
            .environmentObject(authViewModel)
    }

    // MARK: - Actions

    private func loadDoorsIfNeeded() async {
        guard let credentials = authViewModel.credentials else { return }
        isLoading = true
        errorMessage = nil

        do {
            doors = try await doorsService.getDoors(credentials: credentials)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to load doors"
        }

        isLoading = false
    }

    private func calculateDistance(to door: Door) -> CLLocationDistance? {
        guard let currentLocation = locationService.currentLocation,
              let position = door.asset.position2d else {
            return nil
        }

        let doorLocation = CLLocation(
            latitude: position.latitude,
            longitude: position.longitude
        )

        return currentLocation.distance(from: doorLocation)
    }

    private func handleUnlock(_ door: Door) {
        guard let credentials = authViewModel.credentials, unlockingDoorId == nil else { return }

        unlockingDoorId = door.id
        errorMessage = nil

        Task {
            // Prepare haptic feedback generator
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()

            do {
                try await doorsService.unlockDoor(door, credentials: credentials)

                // Success haptic feedback
                generator.notificationOccurred(.success)

                // Show success feedback for 1.5s
                try? await Task.sleep(nanoseconds: 1_500_000_000)
            } catch let error as APIError {
                errorMessage = error.errorDescription
                generator.notificationOccurred(.error)
            } catch {
                errorMessage = "Failed to unlock \(door.name)"
                generator.notificationOccurred(.error)
            }

            unlockingDoorId = nil
        }
    }
}
