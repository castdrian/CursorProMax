import Dispatch
import os

final class CursorPresenter: @unchecked Sendable {
    private struct State {
        var pendingScale: Double?
        var isDraining = false
    }

    private let queue = DispatchQueue(label: "dev.adrian.cursorpromax.presenter", qos: .userInteractive)
    private let state = OSAllocatedUnfairLock(initialState: State())
    private var appliedScale: Double?

    func present(scale: Double) {
        let shouldDrain = state.withLock { state in
            state.pendingScale = scale
            defer { state.isDraining = true }
            return !state.isDraining
        }
        if shouldDrain {
            queue.async { [self] in drain() }
        }
    }

    func restore(scale: Double, synchronously: Bool) {
        state.withLock { $0.pendingScale = nil }
        let restore: @Sendable () -> Void = { [self] in
            WindowServer.setCursorScale(scale)
            appliedScale = nil
        }
        if synchronously {
            queue.sync(execute: restore)
        } else {
            queue.async(execute: restore)
        }
    }

    private func drain() {
        while let scale = nextScale() {
            if let appliedScale, abs(appliedScale - scale) < 0.0005 { continue }
            WindowServer.setCursorScale(scale)
            appliedScale = scale
        }
    }

    private func nextScale() -> Double? {
        state.withLock { state in
            let scale = state.pendingScale
            state.pendingScale = nil
            if scale == nil {
                state.isDraining = false
            }
            return scale
        }
    }
}
