import CoreLocation
import Foundation

/// Service for door operations
class DoorsService {
    private let apiClient: APIClient
    private let keyStore: KeychainKeyStore

    init(apiClient: APIClient, keyStore: KeychainKeyStore) {
        self.apiClient = apiClient
        self.keyStore = keyStore
    }

    // MARK: - Door Operations

    /// Fetch list of available doors
    func getDoors(credentials: Credentials) async throws -> [Door] {
        let response = try await apiClient.getDoors(authToken: credentials.authToken)
        return response.mostInvokedPublicationsList
    }

    /// Unlock a specific door by ID
    func unlockDoor(doorId: String, credentials: Credentials) async throws {
        // Get all doors to find the requested one
        let doors = try await getDoors(credentials: credentials)

        guard let door = doors.first(where: { $0.id == doorId }) else {
            throw DoorsServiceError.doorNotFound
        }

        guard let operation = door.operations.first else {
            throw DoorsServiceError.noOperationsAvailable
        }

        // Load private key from Keychain
        let privateKey = try keyStore.loadKey(identifier: credentials.loginKeyIdentifier)

        // Create authentication proof
        let proof = try Signing.createProof(certBase64: credentials.certBase64, privateKey: privateKey)

        // Execute unlock operation
        try await apiClient.unlockDoor(operationId: operation.id, proof: proof, authToken: credentials.authToken)
    }

    /// Unlock a door
    func unlockDoor(_ door: Door, credentials: Credentials) async throws {
        guard let operation = door.operations.first else {
            throw DoorsServiceError.noOperationsAvailable
        }

        // Load private key from Keychain
        let privateKey = try keyStore.loadKey(identifier: credentials.loginKeyIdentifier)

        // Create authentication proof
        let proof = try Signing.createProof(certBase64: credentials.certBase64, privateKey: privateKey)

        // Execute unlock operation
        try await apiClient.unlockDoor(operationId: operation.id, proof: proof, authToken: credentials.authToken)
    }

    /// Find nearest door based on current location
    func findNearestDoor(doors: [Door], currentLocation: CLLocation) -> (door: Door, distance: CLLocationDistance)? {
        let doorsWithLocation = doors.filter { $0.asset.position2d != nil }

        guard let nearest = doorsWithLocation.min(by: { door1, door2 in
            guard let pos1 = door1.asset.position2d,
                  let pos2 = door2.asset.position2d else {
                return false
            }

            let loc1 = CLLocation(latitude: pos1.latitude, longitude: pos1.longitude)
            let loc2 = CLLocation(latitude: pos2.latitude, longitude: pos2.longitude)

            let dist1 = currentLocation.distance(from: loc1)
            let dist2 = currentLocation.distance(from: loc2)

            return dist1 < dist2
        }), let position = nearest.asset.position2d else {
            return nil
        }

        let doorLocation = CLLocation(latitude: position.latitude, longitude: position.longitude)
        let distance = currentLocation.distance(from: doorLocation)

        return (nearest, distance)
    }
}

// MARK: - Errors

enum DoorsServiceError: Error, LocalizedError {
    case doorNotFound
    case noOperationsAvailable

    var errorDescription: String? {
        switch self {
        case .doorNotFound:
            return "Door not found"
        case .noOperationsAvailable:
            return "Door has no unlock operations available"
        }
    }
}
