import SwiftUI

/// Root view that switches between login and doors based on auth state
struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                DoorsListView()
            } else {
                LoginView()
            }
        }
    }
}
