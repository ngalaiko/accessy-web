import Combine
import CoreLocation
import Foundation

/// Service for managing nearest door functionality
@MainActor
class NearestDoorService: ObservableObject {
    @Published var doors: [Door] = []
    @Published var nearestDoor: Door?
    @Published var distanceToNearest: CLLocationDistance?
    @Published var isLoadingDoors = false
    @Published var errorMessage: String?

    private let doorsService: DoorsService

    init(doorsService: DoorsService) {
        self.doorsService = doorsService
    }

    // MARK: - Public Methods

    /// Load doors from API
    func loadDoors(credentials: Credentials) async {
        isLoadingDoors = true
        errorMessage = nil

        do {
            doors = try await doorsService.getDoors(credentials: credentials)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingDoors = false
    }

    /// Update nearest door based on current location
    func updateNearestDoor(currentLocation: CLLocation?) {
        guard let location = currentLocation else {
            nearestDoor = nil
            distanceToNearest = nil
            return
        }

        if let result = doorsService.findNearestDoor(doors: doors, currentLocation: location) {
            nearestDoor = result.door
            distanceToNearest = result.distance
        } else {
            nearestDoor = nil
            distanceToNearest = nil
        }
    }

    /// Unlock the nearest door
    func unlockNearestDoor(credentials: Credentials) async throws {
        guard let door = nearestDoor else {
            throw NearestDoorServiceError.noNearestDoor
        }

        try await doorsService.unlockDoor(door, credentials: credentials)
    }
}

// MARK: - Errors

enum NearestDoorServiceError: Error, LocalizedError {
    case noNearestDoor

    var errorDescription: String? {
        switch self {
        case .noNearestDoor:
            return "No nearest door available"
        }
    }
}
