import AppKit
import Combine
import Observation
import Sparkle

@Observable
@MainActor
final class UpdateController: NSObject, SPUStandardUserDriverDelegate {
    private(set) var canCheckForUpdates = false
    private(set) var hasPendingUpdate = false

    @ObservationIgnored private var updaterController: SPUStandardUpdaterController!
    @ObservationIgnored private var canCheckSubscription: AnyCancellable?

    override init() {
        super.init()
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: self)
        canCheckSubscription = updaterController.updater.publisher(for: \.canCheckForUpdates, options: [.initial, .new])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] canCheck in
                self?.canCheckForUpdates = canCheck
            }
    }

    func checkForUpdates() {
        NSApp.activate()
        updaterController.checkForUpdates(nil)
    }

    nonisolated var supportsGentleScheduledUpdateReminders: Bool { true }

    nonisolated func standardUserDriverShouldHandleShowingScheduledUpdate(_ update: SUAppcastItem, andInImmediateFocus immediateFocus: Bool) -> Bool {
        true
    }

    nonisolated func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
        MainActor.assumeIsolated {
            if !state.userInitiated {
                hasPendingUpdate = true
            }
            NSApp.activate()
        }
    }

    nonisolated func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
        MainActor.assumeIsolated {
            hasPendingUpdate = false
        }
    }

    nonisolated func standardUserDriverWillFinishUpdateSession() {
        MainActor.assumeIsolated {
            hasPendingUpdate = false
        }
    }
}
