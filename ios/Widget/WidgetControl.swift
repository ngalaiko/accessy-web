import AppIntents
import SwiftUI
import WidgetKit

struct AccessyWidgetControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "rocks.galaiko.AccessyApp.AccessyWidget"
        ) {
            ControlWidgetButton(action: OpenAppAndUnlockIntent()) {
                Image(systemName: "key.horizontal.fill")
                Text("Unlock")
            }
        }
        .displayName("Open Nearest Door")
        .description("Opens the app and unlocks the door closest to your location")
    }
}

enum LaunchTarget: String, AppEnum {
    case unlockNearest

    static var typeDisplayRepresentation = TypeDisplayRepresentation("Launch Target")
    static var caseDisplayRepresentations = [
        LaunchTarget.unlockNearest: DisplayRepresentation("Unlock Nearest")
    ]
}

struct OpenAppAndUnlockIntent: OpenIntent {
    static let title: LocalizedStringResource = "Unlock Nearest Door"

    @Parameter(title: "Target")
    var target: LaunchTarget

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        guard let url = URL(string: "accessy://unlock-nearest") else {
            fatalError("Invalid hardcoded URL")
        }
        return .result(opensIntent: OpenURLIntent(url))
    }
}
