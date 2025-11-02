import Foundation

/// JWT decoding utilities
class JWT {
    /// Decode JWT payload without verification (server already verified)
    static func decodePayload(_ token: String) throws -> JWTPayload {
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else {
            throw CryptoError.invalidKeyFormat
        }

        let payloadPart = String(parts[1])
        guard let data = Encryption.safeB64Decode(payloadPart) else {
            throw CryptoError.invalidKeyFormat
        }

        let decoder = JSONDecoder()
        return try decoder.decode(JWTPayload.self, from: data)
    }
}
