import Combine
import Foundation

/// Manages deep link actions triggered from widgets or external sources
@MainActor
class DeepLinkHandler: ObservableObject {
    @Published var pendingAction: DeepLinkAction?

    enum DeepLinkAction {
        case unlockNearest
    }

    /// Handle incoming URL from widget or external source
    func handle(url: URL) {
        guard url.scheme == "accessy" else { return }

        switch url.host {
        case "unlock-nearest":
            pendingAction = .unlockNearest
        default:
            break
        }
    }

    /// Clear the pending action after it's been processed
    func clearAction() {
        pendingAction = nil
    }
}
