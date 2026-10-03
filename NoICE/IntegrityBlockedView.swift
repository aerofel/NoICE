//
//  IntegrityBlockedView.swift
//  NoICE
//
//  Full-screen notice shown instead of the app on a jailbroken device.
//

import SwiftUI

struct IntegrityBlockedView: View {
    /// Same status line as the main header ("FAA · WINTER 2026-27 · °C").
    let statusLine: String

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBreathing = false

    private var deviceName: String {
        UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
    }

    private var systemName: String {
        UIDevice.current.userInterfaceIdiom == .pad ? "iPadOS" : "iOS"
    }

    private var warm: Color {
        colorScheme == .dark
            ? Color(red: 1.0, green: 0.45, blue: 0.4)
            : Color(red: 0.85, green: 0.2, blue: 0.18)
    }

    var body: some View {
        VStack(spacing: 0) {
            HeaderBanner(statusLine: statusLine)
            content
        }
        .background {
            ZStack {
                Color(.systemGroupedBackground)
                RadialGradient(
                    colors: [warm.opacity(colorScheme == .dark ? 0.22 : 0.12), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 420
                )
            }
            .ignoresSafeArea()
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
    }

    private var content: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 32)

                    shield
                        .padding(.bottom, 28)

                    card

                    Spacer(minLength: 32)

                    Label("Device integrity check", systemImage: "checkmark.shield")
                        .font(.system(size: 10.5, weight: .semibold))
                        .tracking(1.4)
                        .textCase(.uppercase)
                        .foregroundStyle(.tertiary)
                        .padding(.bottom, 12)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: 460)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    // MARK: - Shield

    private var shield: some View {
        ZStack {
            Circle()
                .fill(warm.opacity(colorScheme == .dark ? 0.35 : 0.22))
                .frame(width: 120, height: 120)
                .blur(radius: 24)
                .scaleEffect(isBreathing ? 1.12 : 0.92)
                .opacity(isBreathing ? 1 : 0.7)

            Circle()
                .strokeBorder(warm.opacity(0.25), lineWidth: 1)
                .frame(width: 112, height: 112)

            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().fill(warm.opacity(colorScheme == .dark ? 0.12 : 0.08)))
                .overlay(Circle().strokeBorder(warm.opacity(0.35), lineWidth: 0.5))
                .frame(width: 92, height: 92)

            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.55, blue: 0.35), warm],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: warm.opacity(0.45), radius: 8, x: 0, y: 4)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Card

    private var card: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Device integrity compromised")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("This \(deviceName) appears to be jailbroken. No-ICE computes hold-over times used for operational decisions and can't run on a device whose integrity can't be guaranteed.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 0.5)

            VStack(alignment: .leading, spacing: 12) {
                step("arrow.uturn.backward.circle.fill", "Restore the \(deviceName) to a standard \(systemName) installation.")
                step("arrow.clockwise.circle.fill", "Reopen No-ICE.")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func step(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(warm)
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Same glass recipe as the main header card, with a warm tint instead of the icy one.
    private var cardBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        return ZStack {
            shape.fill(.ultraThinMaterial)

            shape.fill(
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [
                            Color(red: 0.3, green: 0.06, blue: 0.05).opacity(0.55),
                            Color(red: 0.16, green: 0.03, blue: 0.03).opacity(0.35),
                          ]
                        : [
                            Color(red: 1.0, green: 0.93, blue: 0.92).opacity(0.6),
                            Color.white.opacity(0.3),
                          ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            shape.fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.12 : 0.55),
                        Color.white.opacity(0),
                    ],
                    startPoint: .topLeading,
                    endPoint: UnitPoint(x: 0.6, y: 0.9)
                )
            )

            shape.strokeBorder(warm.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 0.5)
        }
        .shadow(
            color: colorScheme == .dark ? Color.black.opacity(0.4) : warm.opacity(0.10),
            radius: 12, x: 0, y: 6
        )
    }
}

#Preview {
    IntegrityBlockedView(statusLine: "FAA \u{00B7} WINTER 2026-27 \u{00B7} \u{00B0}C")
}
