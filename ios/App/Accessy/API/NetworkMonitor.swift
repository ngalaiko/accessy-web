import Combine
import Foundation
import Network

/// Monitor network connectivity status
/// Uses Apple's Network framework to track reachability
@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isConnected = true
    @Published private(set) var connectionType: NWInterface.InterfaceType?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.accessy.networkmonitor")

    private init() {
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
            }
        }
        monitor.start(queue: queue)
    }

    nonisolated private func stopMonitoring() {
        monitor.cancel()
    }

    /// Check if network is available, throw error if not
    func ensureConnected() throws {
        guard isConnected else {
            throw APIError.networkError
        }
    }

    deinit {
        stopMonitoring()
    }
}
