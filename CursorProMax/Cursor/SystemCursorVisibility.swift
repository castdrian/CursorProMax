import CoreGraphics
import Darwin

@MainActor
final class SystemCursorVisibility {
    private typealias DefaultConnectionFunction = @convention(c) () -> Int32
    private typealias SetConnectionPropertyFunction = @convention(c) (Int32, Int32, CFString, CFTypeRef) -> Int32

    private(set) var isHidden = false
    let canHideInBackground: Bool

    init() {
        canHideInBackground = Self.allowCursorControlInBackground()
    }

    func hide() {
        guard !isHidden, canHideInBackground else { return }
        isHidden = CGDisplayHideCursor(CGMainDisplayID()) == .success
    }

    func show() {
        guard isHidden else { return }
        CGDisplayShowCursor(CGMainDisplayID())
        isHidden = false
    }

    private static func allowCursorControlInBackground() -> Bool {
        let defaultHandle = UnsafeMutableRawPointer(bitPattern: -2)
        guard let defaultConnectionSymbol = dlsym(defaultHandle, "_CGSDefaultConnection"),
              let setPropertySymbol = dlsym(defaultHandle, "CGSSetConnectionProperty")
        else { return false }
        let defaultConnection = unsafeBitCast(defaultConnectionSymbol, to: DefaultConnectionFunction.self)
        let setConnectionProperty = unsafeBitCast(setPropertySymbol, to: SetConnectionPropertyFunction.self)
        let connection = defaultConnection()
        let result = setConnectionProperty(connection, connection, "SetsCursorInBackground" as CFString, kCFBooleanTrue)
        return result == 0
    }
}
