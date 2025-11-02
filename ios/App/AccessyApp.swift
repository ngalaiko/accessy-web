import Combine
import SwiftUI

@main
struct AccessyApp: App {
    // Create service instances
    private let keyStore: KeychainKeyStore
    private let credentialsStore: CredentialsStore
    private let apiClient: APIClient
    private let authService: AuthService
    private let doorsService: DoorsService

    // ObservableObject services
    @StateObject private var locationService: LocationService
    @StateObject private var nearestDoorService: NearestDoorService
    @StateObject private var deepLinkHandler: DeepLinkHandler
    @StateObject private var authViewModel: AuthViewModel

    init() {
        // Initialize storage and API layers
        let keyStore = KeychainKeyStore()
        let credentialsStore = CredentialsStore(keyStore: keyStore)
        let apiClient = APIClient()

        // Initialize services
        let authService = AuthService(apiClient: apiClient, keyStore: keyStore)
        let doorsService = DoorsService(apiClient: apiClient, keyStore: keyStore)
        let locationService = LocationService()
        let nearestDoorService = NearestDoorService(doorsService: doorsService)
        let deepLinkHandler = DeepLinkHandler()
        let authViewModel = AuthViewModel(authService: authService, credentialsStore: credentialsStore)

        // Store non-observable services
        self.keyStore = keyStore
        self.credentialsStore = credentialsStore
        self.apiClient = apiClient
        self.authService = authService
        self.doorsService = doorsService

        // Store observable services as StateObjects
        _locationService = StateObject(wrappedValue: locationService)
        _nearestDoorService = StateObject(wrappedValue: nearestDoorService)
        _deepLinkHandler = StateObject(wrappedValue: deepLinkHandler)
        _authViewModel = StateObject(wrappedValue: authViewModel)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.keyStore, keyStore)
                .environment(\.credentialsStore, credentialsStore)
                .environment(\.apiClient, apiClient)
                .environment(\.authService, authService)
                .environment(\.doorsService, doorsService)
                .environmentObject(locationService)
                .environmentObject(nearestDoorService)
                .environmentObject(deepLinkHandler)
                .environmentObject(authViewModel)
                .onOpenURL { url in
                    deepLinkHandler.handle(url: url)
                }
        }
    }
}
