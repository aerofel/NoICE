//
//  NoICEApp.swift
//  NoICE
//
//  Created by Philippe LE GALL on 16/01/2026.
//

import SwiftUI
import HOTKit
import HOTKitNearbyShare

@main
struct NoICEApp: App {
    @StateObject private var configuration = DefaultHOTConfiguration()
    @StateObject private var hotState = HOTState()
    @StateObject private var nearbyShare = NearbyShareService()

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme

    var body: some Scene {
        WindowGroup {
            if DeviceIntegrity.isCompromised {
                IntegrityBlockedView(statusLine: configuration.headerStatusLine)
            } else {
                mainView
            }
        }
        // Nearby Share only runs while the app is on screen. `.inactive` (Control Center,
        // alerts, multitasking) keeps it running; only the background stops it.
        .onChange(of: scenePhase, initial: true) { _, phase in
            guard !DeviceIntegrity.isCompromised else { return }
            switch phase {
            case .active: nearbyShare.start()
            case .background: nearbyShare.stop()
            default: break
            }
        }
    }

    private var mainView: some View {
        ContentView(configuration: configuration, hotState: hotState)
            .environmentObject(nearbyShare)
            .sheet(item: $nearbyShare.incoming) { offer in
                IncomingShareSheet(
                    offer: offer,
                    configuration: configuration,
                    hotState: hotState,
                    tint: icy,
                    onAccept: { accept(offer) },
                    onDecline: { nearbyShare.incoming = nil }
                )
            }
            #if DEBUG
            // Headless simulator check of the apply path: `-NearbyShareDemoAutoAccept YES`.
            .onChange(of: nearbyShare.incoming) { _, offer in
                guard let offer, UserDefaults.standard.bool(forKey: "NearbyShareDemoAutoAccept") else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { accept(offer) }
            }
            #endif
    }

    private var icy: Color {
        colorScheme == .dark
            ? Color(red: 0.4, green: 0.8, blue: 1.0)
            : Color(red: 0.2, green: 0.5, blue: 0.8)
    }

    /// Switch to the sender's tables first, then adopt its state (HOTView picks it up).
    private func accept(_ offer: IncomingShare) {
        if configuration.dataSource != offer.snapshot.source {
            configuration.dataSource = offer.snapshot.source
        }
        hotState.applyShared(
            offer.snapshot,
            loader: configuration.hotLoader,
            temperatureUnit: configuration.temperatureUnit,
            receivedAt: offer.receivedAt
        )
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        nearbyShare.incoming = nil
    }
}
