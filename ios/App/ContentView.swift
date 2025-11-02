import SwiftUI

/// Root view that switches between login and doors based on auth state
struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var locationService: LocationService

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                DoorsListView()
                    .task {
                        locationService.requestAuthorization()
                        locationService.startUpdatingLocation()
                    }
            } else {
                LoginView()
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                locationService.requestAuthorization()
                locationService.startUpdatingLocation()
            } else {
                locationService.stopUpdatingLocation()
            }
        }
    }
}
