import Foundation

// MARK: - Door

struct Door: Codable, Identifiable {
    let publicationId: String
    let name: String
    let asset: Asset
    let favorite: Bool

    var id: String { publicationId }
    var assetId: String { asset.id }
    var assetName: String { asset.name }
    var operations: [Operation] { asset.operations }

    struct Asset: Codable {
        let id: String
        let name: String
        let operations: [Operation]
        let position2d: Position?
    }

    struct Position: Codable {
        let latitude: Double
        let longitude: Double
    }

    struct Operation: Codable, Identifiable {
        let id: String
        let name: String
    }

    enum CodingKeys: String, CodingKey {
        case publicationId = "id"
        case name
        case asset
        case favorite
    }
}

// MARK: - API Responses

struct DoorsResponse: Codable {
    let mostInvokedPublicationsList: [Door]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var arrayContainer = try container.nestedUnkeyedContainer(forKey: .mostInvokedPublicationsList)

        var doors: [Door] = []
        while !arrayContainer.isAtEnd {
            // Try to decode as Door, skip if it fails (handles mixed array with numbers)
            if let door = try? arrayContainer.decode(Door.self) {
                doors.append(door)
            } else {
                // Skip non-object elements (like the numbers in the array)
                _ = try? arrayContainer.decode(Int.self)
            }
        }

        mostInvokedPublicationsList = doors
    }

    enum CodingKeys: String, CodingKey {
        case mostInvokedPublicationsList
    }
}
