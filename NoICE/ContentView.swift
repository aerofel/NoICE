//
//  ContentView.swift
//  NoICE
//
//  Created by Philippe LE GALL on 16/01/2026.
//

import SwiftUI
import HOTKit

struct ContentView<Configuration: HOTConfiguration>: View {
    @ObservedObject var configuration: Configuration
    @ObservedObject var hotState: HOTState

    @Environment(\.colorScheme) private var colorScheme

    private var icy: Color {
        colorScheme == .dark
            ? Color(red: 0.4, green: 0.8, blue: 1.0)
            : Color(red: 0.2, green: 0.5, blue: 0.8)
    }

    /// "FAA · WINTER 2026-27 · °C", derived from the loaded tables and the unit.
    private var statusLine: String {
        var parts: [String] = [configuration.dataSource]
        if let label = configuration.hotLoader.sourceLabel {
            // "Source: FAA Winter 2026-27" -> "Winter 2026-27"
            let words = label
                .replacingOccurrences(of: "Source:", with: "")
                .split(separator: " ")
                .map(String.init)
            if words.count > 1 {
                parts.append(words.dropFirst().joined(separator: " "))
            }
        }
        parts.append("\u{00B0}\(configuration.temperatureUnit)")
        return parts.joined(separator: " \u{00B7} ").uppercased()
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

    private var logoView: some View {
        ZStack {
            Circle()
                .fill(icy.opacity(colorScheme == .dark ? 0.35 : 0.25))
                .frame(width: 64, height: 64)
                .blur(radius: 14)
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.18 : 0.5), lineWidth: 0.5)
                )
                .shadow(color: icy.opacity(0.45), radius: 8, x: 0, y: 4)
        }
        .frame(width: 56, height: 56)
    }

    private var titleView: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("No-ICE")
                .font(.system(size: 38, weight: .heavy))
                .tracking(4)
                .foregroundStyle(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [
                                Color(red: 0.7, green: 0.9, blue: 1.0),
                                Color.white,
                                Color(red: 0.3, green: 0.75, blue: 1.0),
                              ]
                            : [
                                Color(red: 0.05, green: 0.3, blue: 0.6),
                                Color(red: 0.1, green: 0.45, blue: 0.8),
                                Color(red: 0.15, green: 0.6, blue: 0.95),
                              ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: colorScheme == .dark
                    ? Color(red: 0.2, green: 0.6, blue: 1.0).opacity(0.35)
                    : Color(red: 0.1, green: 0.3, blue: 0.6).opacity(0.25),
                    radius: 6, x: 0, y: 2)

            // Live status: source, season, unit. Tapping opens the same menu as the gear.
            Menu {
                settingsMenuContent
            } label: {
                HStack(spacing: 5) {
                    Circle()
                        .fill(icy)
                        .frame(width: 5, height: 5)
                    Text(statusLine)
                        .font(.system(size: 10.5, weight: .semibold))
                        .tracking(1.4)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var settingsButton: some View {
        Menu {
            settingsMenuContent
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(icy)
                .frame(width: 40, height: 40)
                .background(
                    Circle().fill(
                        colorScheme == .dark
                            ? Color.white.opacity(0.08)
                            : Color(red: 0.1, green: 0.3, blue: 0.6).opacity(0.08)
                    )
                )
                .overlay(
                    Circle().strokeBorder(
                        colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.7),
                        lineWidth: 0.5
                    )
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Settings")
    }

    private var headerBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        return ZStack {
            // Glass
            shape.fill(.ultraThinMaterial)

            // Icy tint
            shape.fill(
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [
                            Color(red: 0.05, green: 0.15, blue: 0.3).opacity(0.6),
                            Color(red: 0.02, green: 0.08, blue: 0.18).opacity(0.4),
                          ]
                        : [
                            Color(red: 0.9, green: 0.95, blue: 1.0).opacity(0.5),
                            Color.white.opacity(0.3),
                          ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Frost highlight along the top edge
            shape.fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.16 : 0.55),
                        Color.white.opacity(0),
                    ],
                    startPoint: .topLeading,
                    endPoint: UnitPoint(x: 0.6, y: 0.9)
                )
            )

            // Thin border for definition
            shape.strokeBorder(
                colorScheme == .dark
                    ? Color.white.opacity(0.14)
                    : Color.black.opacity(0.07),
                lineWidth: 0.5
            )
        }
        .shadow(
            color: colorScheme == .dark ? Color.black.opacity(0.4) : Color(red: 0.1, green: 0.3, blue: 0.6).opacity(0.10),
            radius: 12, x: 0, y: 6
        )
    }

    private var headerView: some View {
        HStack(spacing: 14) {
            logoView
            titleView
            Spacer(minLength: 8)
            settingsButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(headerBackground)
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            HOTView(configuration: configuration, hotState: hotState)
        }
    }
}

#Preview {
    ContentView(configuration: DefaultHOTConfiguration(), hotState: HOTState())
}
