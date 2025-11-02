import CoreLocation
import Foundation

/// Location overrides for specific doors
private let doorLocationOverrides: [String: CLLocationCoordinate2D] = [
    "F9114E43-B180-470F-B953-2D90FB67AA72": CLLocationCoordinate2D(
        latitude: 57.711941,
        longitude: 11.945427
    ), // P.O nr 21
    "B450D23A-451A-49B8-9D9A-07F7BB3EC36C": CLLocationCoordinate2D(
        latitude: 57.711437,
        longitude: 11.946004
    ),
    // United Spaces Theatre Plan 2
    "F96EBB6D-B9EC-422F-905F-8A3B9575EA30": CLLocationCoordinate2D(
        latitude: 57.711603,
        longitude: 11.946576
    ) // United Spaces reception Plan 2
]

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
        return response.mostInvokedPublicationsList.map { fixDoor($0) }
    }

    /// Apply location overrides to a door if available
    private func fixDoor(_ door: Door) -> Door {
        guard let override = doorLocationOverrides[door.id] else {
            return door
        }

        let newPosition = Door.Position(latitude: override.latitude, longitude: override.longitude)
        let newAsset = Door.Asset(
            id: door.asset.id,
            name: door.asset.name,
            operations: door.asset.operations,
            position2d: newPosition
        )

        return Door(
            publicationId: door.publicationId,
            name: door.name,
            asset: newAsset,
            favorite: door.favorite
        )
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
