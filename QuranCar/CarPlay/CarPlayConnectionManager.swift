import Foundation
import CarPlay

extension Notification.Name {
    static let CPTemplateApplicationSceneDidConnect = Notification.Name("CPTemplateApplicationSceneDidConnect")
    static let CPTemplateApplicationSceneDidDisconnect = Notification.Name("CPTemplateApplicationSceneDidDisconnect")
}

class CarPlayConnectionManager: ObservableObject {
    static let shared = CarPlayConnectionManager()

    @Published var isConnected = false {
        didSet {
            Logger.debug("CarPlayConnectionManager: Connection state changed to: \(isConnected)")
        }
    }

    private init() {
        Logger.debug("CarPlayConnectionManager: Initializing")
        setupNotifications()
    }

    private func setupNotifications() {
        // Remove any existing observers first
        NotificationCenter.default.removeObserver(self)

        // Observe CarPlay connection
        NotificationCenter.default.addObserver(
            forName: .CPTemplateApplicationSceneDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Logger.debug("CarPlayConnectionManager: Received connect notification")
            self?.handleCarPlayConnection()
        }

        // Observe CarPlay disconnection
        NotificationCenter.default.addObserver(
            forName: .CPTemplateApplicationSceneDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Logger.debug("CarPlayConnectionManager: Received disconnect notification")
            self?.handleCarPlayDisconnection()
        }

        // Also observe system CarPlay connection status
        NotificationCenter.default.addObserver(
            forName: UIScene.didDisconnectNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let scene = notification.object as? CPTemplateApplicationScene {
                Logger.debug("CarPlayConnectionManager: System disconnect notification for CarPlay scene")
                self?.handleCarPlayDisconnection()
            }
        }
    }

    private func handleCarPlayConnection() {
        DispatchQueue.main.async {
            Logger.debug("CarPlayConnectionManager: Setting connected state to true")
            self.isConnected = true
        }
    }

    private func handleCarPlayDisconnection() {
        DispatchQueue.main.async {
            Logger.debug("CarPlayConnectionManager: Setting connected state to false")
            self.isConnected = false
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}