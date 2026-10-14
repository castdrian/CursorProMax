import CoreGraphics
import Darwin

enum WindowServer {
    static let cursorScaleRange: ClosedRange<Double> = 0.5...15.9

    private typealias ConnectionFunction = @convention(c) () -> Int32
    private typealias GetCursorScaleFunction = @convention(c) (Int32, UnsafeMutablePointer<Float>) -> Int32
    private typealias SetCursorScaleFunction = @convention(c) (Int32, Float) -> Int32
    private typealias FindCursorIsDisabledFunction = @convention(c) () -> Bool
    private typealias DisableFindCursorFunction = @convention(c) (Int32, Bool) -> Int32

    private struct Functions: @unchecked Sendable {
        let connection: ConnectionFunction
        let getCursorScale: GetCursorScaleFunction
        let setCursorScale: SetCursorScaleFunction
        let findCursorIsDisabled: FindCursorIsDisabledFunction
        let disableFindCursor: DisableFindCursorFunction

        init?() {
            guard let handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_NOW) else { return nil }
            func load<Function>(_ name: String, as type: Function.Type) -> Function? {
                dlsym(handle, name).map { unsafeBitCast($0, to: type) }
            }
            guard let connection = load("SLSMainConnectionID", as: ConnectionFunction.self),
                  let getCursorScale = load("SLSGetCursorScale", as: GetCursorScaleFunction.self),
                  let setCursorScale = load("SLSSetCursorScale", as: SetCursorScaleFunction.self),
                  let findCursorIsDisabled = load("SLSPackagesFindCursorIsDisabled", as: FindCursorIsDisabledFunction.self),
                  let disableFindCursor = load("SLSPackagesDisableFindCursor", as: DisableFindCursorFunction.self)
            else { return nil }
            self.connection = connection
            self.getCursorScale = getCursorScale
            self.setCursorScale = setCursorScale
            self.findCursorIsDisabled = findCursorIsDisabled
            self.disableFindCursor = disableFindCursor
        }
    }

    private static let functions = Functions()

    static var isAvailable: Bool { functions != nil }

    static func cursorScale() -> Double? {
        guard let functions else { return nil }
        var scale: Float = 0
        guard functions.getCursorScale(functions.connection(), &scale) == 0, scale > 0 else { return nil }
        return Double(scale)
    }

    @discardableResult
    static func setCursorScale(_ scale: Double) -> Bool {
        guard let functions else { return false }
        let clamped = min(max(scale, cursorScaleRange.lowerBound), cursorScaleRange.upperBound)
        return functions.setCursorScale(functions.connection(), Float(clamped)) == 0
    }

    static func isShakeToLocateDisabled() -> Bool? {
        guard let functions else { return nil }
        _ = functions.connection()
        return functions.findCursorIsDisabled()
    }

    static func setShakeToLocateDisabled(_ disabled: Bool) {
        guard let functions else { return }
        _ = functions.disableFindCursor(functions.connection(), disabled)
    }
}
