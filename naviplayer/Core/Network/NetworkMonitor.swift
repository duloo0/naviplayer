//
//  NetworkMonitor.swift
//  naviplayer
//
//  Monitors network connectivity for adaptive preloading
//

import Foundation
import Network
import Combine

@MainActor
final class NetworkMonitor: ObservableObject {
    // MARK: - Singleton
    static let shared = NetworkMonitor()

    // MARK: - Published State
    @Published private(set) var connectionType: ConnectionType = .unknown
    @Published private(set) var isExpensive: Bool = false
    @Published private(set) var isConstrained: Bool = false
    @Published private(set) var isConnected: Bool = true

    // MARK: - Connection Types
    enum ConnectionType: String {
        case wifi = "WiFi"
        case cellular = "Cellular"
        case wired = "Wired"
        case unknown = "Unknown"

        var recommendedPreloadCount: Int {
            switch self {
            case .wifi, .wired: return 5
            case .cellular: return 2
            case .unknown: return 3
            }
        }
    }

    // MARK: - Private
    private let monitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "com.naviplayer.networkmonitor")

    // MARK: - Init
    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.updatePath(path)
            }
        }
        monitor.start(queue: monitorQueue)
    }

    private func updatePath(_ path: NWPath) {
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained

        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wired
        } else {
            connectionType = .unknown
        }
    }

    // MARK: - Computed Properties

    /// Recommended preload count based on network conditions
    var recommendedPreloadCount: Int {
        if !isConnected {
            return 0
        }

        // Reduce on expensive/constrained connections
        if isExpensive || isConstrained {
            return max(1, connectionType.recommendedPreloadCount / 2)
        }

        return connectionType.recommendedPreloadCount
    }

    /// Whether high quality streaming is recommended
    var highQualityRecommended: Bool {
        isConnected && !isExpensive && !isConstrained && (connectionType == .wifi || connectionType == .wired)
    }
}
