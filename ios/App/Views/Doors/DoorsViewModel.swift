import Combine
import Foundation
import UIKit

/// View model for doors list and unlock operations
/// Handles business logic for door management
@MainActor
class DoorsViewModel: ObservableObject {
    // MARK: - Published State

    @Published var doors: [Door] = []
    @Published var isLoading = false
    @Published var unlockingDoorId: String?
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let doorsService: DoorsService

    // MARK: - Initialization

    init(doorsService: DoorsService) {
        self.doorsService = doorsService
    }

    // MARK: - Actions

    /// Load available doors from API
    func loadDoors(credentials: Credentials) async {
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

    /// Unlock a specific door
    func unlockDoor(_ door: Door, credentials: Credentials) async {
        guard unlockingDoorId == nil else { return }

        unlockingDoorId = door.id
        errorMessage = nil

        // Prepare haptic feedback generator
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()

        do {
            try await doorsService.unlockDoor(door, credentials: credentials)

            // Success haptic feedback
            generator.notificationOccurred(.success)

            // Show success feedback for 1.5s
            do {
                try await Task.sleep(nanoseconds: Constants.unlockFeedbackDuration)
            } catch {
                // Task was cancelled, ignore
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription

            // Error haptic feedback
            generator.notificationOccurred(.error)
        } catch {
            errorMessage = "Failed to unlock \(door.name)"

            // Error haptic feedback
            generator.notificationOccurred(.error)
        }

        unlockingDoorId = nil
    }

    // MARK: - Constants

    private enum Constants {
        static let unlockFeedbackDuration: UInt64 = 1_500_000_000
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
