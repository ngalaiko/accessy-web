import SwiftUI

// MARK: - Environment Keys for Services

private struct KeychainKeyStoreKey: EnvironmentKey {
    static let defaultValue = KeychainKeyStore()
}

private struct CredentialsStoreKey: EnvironmentKey {
    static let defaultValue = CredentialsStore(keyStore: KeychainKeyStore())
}

private struct APIClientKey: EnvironmentKey {
    static let defaultValue = APIClient()
}

private struct AuthServiceKey: EnvironmentKey {
    static let defaultValue = AuthService(
        apiClient: APIClient(),
        keyStore: KeychainKeyStore()
    )
}

private struct DoorsServiceKey: EnvironmentKey {
    static let defaultValue = DoorsService(
        apiClient: APIClient(),
        keyStore: KeychainKeyStore()
    )
}

// MARK: - EnvironmentValues Extensions

extension EnvironmentValues {
    var keyStore: KeychainKeyStore {
        get { self[KeychainKeyStoreKey.self] }
        set { self[KeychainKeyStoreKey.self] = newValue }
    }

    var credentialsStore: CredentialsStore {
        get { self[CredentialsStoreKey.self] }
        set { self[CredentialsStoreKey.self] = newValue }
    }

    var apiClient: APIClient {
        get { self[APIClientKey.self] }
        set { self[APIClientKey.self] = newValue }
    }

    var authService: AuthService {
        get { self[AuthServiceKey.self] }
        set { self[AuthServiceKey.self] = newValue }
    }

    var doorsService: DoorsService {
        get { self[DoorsServiceKey.self] }
        set { self[DoorsServiceKey.self] = newValue }
    }
}
