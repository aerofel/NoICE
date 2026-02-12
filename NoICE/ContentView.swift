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

    private var headerView: some View {
        HStack(spacing: 14) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color(red: 0.2, green: 0.6, blue: 0.9).opacity(0.5), radius: 6, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 0) {
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

                Text("Streamlined Hold-Over Time")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .tracking(1.5)
            }

            Spacer()

            Menu {
                Section("Data Source") {
                    Button {
                        if let config = configuration as? DefaultHOTConfiguration {
                            config.dataSource = "FAA"
                        }
                    } label: {
                        HStack {
                            Text("FAA")
                            if configuration.dataSource == "FAA" {
                                Image(systemName: "checkmark")
                            }
                        }
                    }

                    Button {
                        if let config = configuration as? DefaultHOTConfiguration {
                            config.dataSource = "TCA"
                        }
                    } label: {
                        HStack {
                            Text("Transport Canada")
                            if configuration.dataSource == "TCA" {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                Section("Temperature") {
                    Button {
                        if let config = configuration as? DefaultHOTConfiguration {
                            config.temperatureUnit = "C"
                        }
                    } label: {
                        HStack {
                            Text("Celsius")
                            if configuration.temperatureUnit == "C" {
                                Image(systemName: "checkmark")
                            }
                        }
                    }

                    Button {
                        if let config = configuration as? DefaultHOTConfiguration {
                            config.temperatureUnit = "F"
                        }
                    } label: {
                        HStack {
                            Text("Fahrenheit")
                            if configuration.temperatureUnit == "F" {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(
                        colorScheme == .dark
                            ? Color(red: 0.4, green: 0.8, blue: 1.0)
                            : Color(red: 0.2, green: 0.5, blue: 0.8)
                    )
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            ZStack {
                // Glass blur effect
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)

                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
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

                // Thin border for definition
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        colorScheme == .dark
                            ? Color.white.opacity(0.12)
                            : Color.black.opacity(0.08),
                        lineWidth: 0.5
                    )
            }
        )
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
