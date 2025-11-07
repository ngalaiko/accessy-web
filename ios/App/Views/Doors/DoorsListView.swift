import CoreLocation
import SwiftUI
import UIKit

/// Pure UI view for doors list
/// All business logic is in DoorsViewModel
struct DoorsListView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var doorsViewModel: DoorsViewModel
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Demo mode banner
                if authViewModel.credentials?.isDemoMode == true {
                    DemoModeBanner()
                }

                Group {
                    if locationManager.isAuthorized {
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
            if doorsViewModel.isLoading && doorsViewModel.doors.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if doorsViewModel.doors.isEmpty {
                Text("No doors available")
                    .foregroundColor(.secondary)
            } else {
                ForEach(doorsViewModel.doors) { door in
                    DoorRow(
                        door: door,
                        isUnlocking: doorsViewModel.unlockingDoorId == door.id,
                        distance: calculateDistance(to: door),
                        onTap: {
                            guard let credentials = authViewModel.credentials else { return }
                            Task { await doorsViewModel.unlockDoor(door, credentials: credentials) }
                        },
                        onFavoriteTap: {
                            guard let credentials = authViewModel.credentials else { return }
                            Task { await doorsViewModel.toggleFavorite(door, credentials: credentials) }
                        }
                    )
                }
            }
        }
        .alert("Error", isPresented: .constant(doorsViewModel.errorMessage != nil)) {
            Button("OK") {
                doorsViewModel.clearError()
            }
        } message: {
            if let error = doorsViewModel.errorMessage {
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
        await doorsViewModel.loadDoors(credentials: credentials)
    }

    private func calculateDistance(to door: Door) -> CLLocationDistance? {
        guard let currentLocation = locationManager.currentLocation,
              let position = door.asset.position2d else {
            return nil
        }

        let doorLocation = CLLocation(
            latitude: position.latitude,
            longitude: position.longitude
        )

        return currentLocation.distance(from: doorLocation)
    }
}
