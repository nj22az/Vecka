import Foundation

enum Log {
    static func d(_ message: @autoclosure () -> String) {
        #if DEBUG
        print(message())
        #endif
    }
    static func w(_ message: @autoclosure () -> String) {
        #if DEBUG
        print("⚠️ " + message())
        #endif
    }
    static func i(_ message: @autoclosure () -> String) {
        #if DEBUG
        print("ℹ️ " + message())
        #endif
    }
    static func e(_ message: @autoclosure () -> String) {
        #if DEBUG
        print("❌ " + message())
        #endif
    }
}

