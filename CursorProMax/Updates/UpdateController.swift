import AppKit
import Combine
import Observation
import Sparkle

@Observable
@MainActor
final class UpdateController {
    private(set) var canCheckForUpdates = false

    @ObservationIgnored private let updaterController: SPUStandardUpdaterController
    @ObservationIgnored private var canCheckSubscription: AnyCancellable?

    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
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
}
