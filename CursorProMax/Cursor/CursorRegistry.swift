import CoreGraphics
import Darwin

struct RegisteredCursor: @unchecked Sendable {
    let pointSize: CGSize
    let hotspot: CGPoint
    let frameCount: Int
    let images: [CGImage]
}

enum CursorRegistry {
    static let systemCursorIdentifiers = 0..<64

    private typealias ConnectionFunction = @convention(c) () -> Int32
    private typealias CopyImagesFunction = @convention(c) (
        Int32, UnsafePointer<CChar>, UnsafeMutablePointer<CGSize>, UnsafeMutablePointer<CGPoint>,
        UnsafeMutablePointer<Int>, UnsafeMutablePointer<Double>, UnsafeMutablePointer<Unmanaged<CFArray>?>
    ) -> Int32
    private typealias RegisterFunction = @convention(c) (
        Int32, UnsafePointer<CChar>, Bool, Bool, CGSize, CGPoint, Int, Double, CFArray, UnsafeMutablePointer<Int32>
    ) -> Int32
    private typealias CoreCursorSetFunction = @convention(c) (Int32, Int32) -> Int32
    private typealias UnregisterAllFunction = @convention(c) (Int32) -> Int32

    private struct Functions: @unchecked Sendable {
        let connection: ConnectionFunction
        let copyImages: CopyImagesFunction
        let register: RegisterFunction
        let coreCursorSet: CoreCursorSetFunction
        let unregisterAll: UnregisterAllFunction

        init?() {
            guard let skyLight = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_NOW),
                  let hiServices = dlopen("/System/Library/Frameworks/ApplicationServices.framework/Frameworks/HIServices.framework/HIServices", RTLD_NOW)
            else { return nil }
            func load<Function>(_ name: String, from handle: UnsafeMutableRawPointer, as type: Function.Type) -> Function? {
                dlsym(handle, name).map { unsafeBitCast($0, to: type) }
            }
            guard let connection = load("SLSMainConnectionID", from: skyLight, as: ConnectionFunction.self),
                  let copyImages = load("SLSCopyRegisteredCursorImages", from: skyLight, as: CopyImagesFunction.self),
                  let register = load("SLSRegisterCursorWithImages", from: skyLight, as: RegisterFunction.self),
                  let coreCursorSet = load("CoreCursorSet", from: hiServices, as: CoreCursorSetFunction.self),
                  let unregisterAll = load("CoreCursorUnregisterAll", from: hiServices, as: UnregisterAllFunction.self)
            else { return nil }
            self.connection = connection
            self.copyImages = copyImages
            self.register = register
            self.coreCursorSet = coreCursorSet
            self.unregisterAll = unregisterAll
        }
    }

    private static let functions = Functions()

    static var isAvailable: Bool { functions != nil }

    static func name(ofSystemCursor identifier: Int) -> String {
        "com.apple.cursor.\(identifier)"
    }

    static func systemCursor(_ identifier: Int) -> RegisteredCursor? {
        guard let functions else { return nil }
        let connection = functions.connection()
        guard functions.coreCursorSet(connection, Int32(identifier)) == 0 else { return nil }
        var size = CGSize.zero
        var hotspot = CGPoint.zero
        var frameCount = 0
        var frameDuration = 0.0
        var images: Unmanaged<CFArray>?
        let result = name(ofSystemCursor: identifier).withCString { cName in
            functions.copyImages(connection, cName, &size, &hotspot, &frameCount, &frameDuration, &images)
        }
        guard result == 0, let list = images?.takeRetainedValue() as? [CGImage], !list.isEmpty else { return nil }
        return RegisteredCursor(pointSize: size, hotspot: hotspot, frameCount: frameCount, images: list)
    }

    @discardableResult
    static func registerGlobally(_ cursor: RegisteredCursor, as name: String) -> Bool {
        guard let functions else { return false }
        var seed: Int32 = 0
        return name.withCString { cName in
            functions.register(
                functions.connection(), cName, true, true,
                cursor.pointSize, cursor.hotspot, cursor.frameCount, 0, cursor.images as CFArray, &seed
            ) == 0
        }
    }

    static func restoreSystemCursors() {
        guard let functions else { return }
        let connection = functions.connection()
        _ = functions.unregisterAll(connection)
        for identifier in systemCursorIdentifiers {
            _ = functions.coreCursorSet(connection, Int32(identifier))
        }
    }
}
