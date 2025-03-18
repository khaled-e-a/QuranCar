import Foundation

enum Logger {
    static func debug(_ message: String) {
        #if DEBUG
        print("Debug: \(message)")
        #endif
    }

    static func info(_ message: String) {
        #if DEBUG
        print("Info: \(message)")
        #endif
    }

    static func error(_ message: String) {
        #if DEBUG
        print("Error: \(message)")
        #endif
    }
}