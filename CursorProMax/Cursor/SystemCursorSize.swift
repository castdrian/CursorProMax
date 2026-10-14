import Foundation

enum SystemCursorSize {
    static func current() -> CGFloat {
        let value = CFPreferencesCopyAppValue("mouseDriverCursorSize" as CFString, "com.apple.universalaccess" as CFString)
        let size = (value as? NSNumber)?.doubleValue ?? 1
        return CGFloat(min(max(size, 1), 4))
    }
}
