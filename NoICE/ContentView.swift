//
//  ContentView.swift
//  NoICE
//
//  Created by Philippe LE GALL on 16/01/2026.
//

import SwiftUI
import HOTKit
import HOTKitNearbyShare

struct ContentView<Configuration: HOTConfiguration>: View {
    @ObservedObject var configuration: Configuration
    @ObservedObject var hotState: HOTState

    @EnvironmentObject private var nearbyShare: NearbyShareService
    @Environment(\.colorScheme) private var colorScheme

    private var icy: Color {
        colorScheme == .dark
            ? Color(red: 0.4, green: 0.8, blue: 1.0)
            : Color(red: 0.2, green: 0.5, blue: 0.8)
    }

    // MARK: - Settings menu

    @ViewBuilder
    private var settingsMenuContent: some View {
        Section("Data Source") {
            sourceButton("FAA", key: "FAA")
            sourceButton("Transport Canada", key: "TCA")
        }
        Section("Temperature") {
            unitButton("Celsius", key: "C")
            unitButton("Fahrenheit", key: "F")
        }
    }

    private func sourceButton(_ title: String, key: String) -> some View {
        Button {
            if let config = configuration as? DefaultHOTConfiguration {
                config.dataSource = key
            }
        } label: {
            HStack {
                Text(title)
                if configuration.dataSource == key {
                    Image(systemName: "checkmark")
                }
            }
        }
    }

    private func unitButton(_ title: String, key: String) -> some View {
        Button {
            if let config = configuration as? DefaultHOTConfiguration {
                config.temperatureUnit = key
            }
        } label: {
            HStack {
                Text(title)
                if configuration.temperatureUnit == key {
                    Image(systemName: "checkmark")
                }
            }
        }
    }

    // MARK: - Header

    private var settingsButton: some View {
        Menu {
            settingsMenuContent
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(icy)
                .headerCircle()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Settings")
    }

    private var shareButton: some View {
        NearbyShareButton(service: nearbyShare, tint: icy) {
            HOTShareSnapshot.capture(
                state: hotState,
                configuration: configuration,
                db: nearbyShare.localInfo.db,
                sender: nearbyShare.localInfo.name
            )
        }
    }

    /// "Sent to 2 devices" after a share.
    @ViewBuilder
    private var shareToast: some View {
        if case .finished(let delivered, let total) = nearbyShare.sendState {
            let text = delivered == total
                ? (delivered == 1 ? "Sent to 1 device" : "Sent to \(delivered) devices")
                : (delivered == 0 ? "Nearby devices could not be reached" : "Sent to \(delivered) of \(total) devices")
            Label(text, systemImage: delivered > 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(delivered > 0 ? Color.green : Color.orange)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(.regularMaterial))
                .overlay(Capsule().strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private var headerView: some View {
        HeaderBanner(statusLine: configuration.headerStatusLine) {
            settingsMenuContent
        } trailing: {
            VStack(spacing: 6) {
                settingsButton
                shareButton
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            HOTView(configuration: configuration, hotState: hotState)
                .overlay(alignment: .top) { shareToast }
                .animation(.spring(response: 0.35, dampingFraction: 0.82), value: nearbyShare.sendState)
        }
    }
}

#Preview {
    ContentView(configuration: DefaultHOTConfiguration(), hotState: HOTState())
        .environmentObject(NearbyShareService())
}
