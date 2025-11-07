import SwiftUI

/// Root view that switches between login and doors based on auth state
struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var locationManager: LocationManager

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                DoorsListView()
                    .task {
                        locationManager.requestAuthorization()
                        locationManager.startUpdatingLocation()
                    }
            } else {
                LoginView()
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                locationManager.requestAuthorization()
                locationManager.startUpdatingLocation()
            } else {
                locationManager.stopUpdatingLocation()
            }
        }
    }
}
