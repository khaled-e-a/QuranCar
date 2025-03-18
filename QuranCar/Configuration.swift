import Foundation

enum Configuration {
    enum Error: Swift.Error {
        case missingKey, invalidValue
    }

    static func value<T>(for key: String) throws -> T where T: LosslessStringConvertible {
        guard let object = Bundle.main.object(forInfoDictionaryKey: key) else {
            Logger.error("Configuration: Missing key: \(key)")
            throw Error.missingKey
        }

        switch object {
        case let value as T:
            Logger.debug("Configuration: Found value: \(value)")
            return value
        case let string as String:
            Logger.debug("Configuration: String value: \(string)")
            guard let value = T(string) else { fallthrough }
            Logger.debug("Configuration: Converted value: \(value)")
            return value
        default:
            Logger.error("Configuration: Invalid value type")
            throw Error.invalidValue
        }
    }
}

extension Configuration {
    static var clientId: String {
        Logger.debug("Configuration: Getting client ID")
        return try! Configuration.value(for: "QURAN_CLIENT_ID")
    }

    static var clientSecret: String {
        Logger.debug("Configuration: Getting client secret")
        return try! Configuration.value(for: "QURAN_CLIENT_SECRET")
    }
}