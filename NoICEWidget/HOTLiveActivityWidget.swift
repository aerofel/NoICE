//
//  HOTLiveActivityWidget.swift
//  NoICEWidget
//
//  Live Activity UI for Hold-Over Time tracking
//

import ActivityKit
import WidgetKit
import SwiftUI
import HOTKit

struct HOTLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HOTActivityAttributes.self) { context in
            // Lock screen/banner UI
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    ExpandedLeadingView(context: context)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    ExpandedTrailingView(context: context)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(context: context)
                }

                DynamicIslandExpandedRegion(.center) {
                    ExpandedCenterView(context: context)
                }
            } compactLeading: {
                CompactLeadingView(context: context)
            } compactTrailing: {
                CompactTrailingView(context: context)
            } minimal: {
                MinimalView(context: context)
            }
        }
    }
}

// MARK: - Shared helpers

private extension ActivityViewContext where Attributes == HOTActivityAttributes {
    var fluidColor: Color { colorForFluidType(state.fluidType) }

    var weatherSymbol: String {
        HOTActivityAttributes.sfSymbolForPrecipitation(state.precipitationType)
    }

    var temperatureText: String {
        "\(Int(state.temperature))\u{00A0}\u{00B0}\(state.temperatureUnit)"
    }

    /// "IV · 75/25"
    var fluidText: String {
        "\(HOTActivityAttributes.fluidTypeRoman(state.fluidType)) \u{00B7} \(Int(state.fluidPercentage))/\(Int(state.waterPercentage))"
    }

    var assuredRatio: Double {
        state.limitTimeSeconds > 0 ? state.assuredTimeSeconds / state.limitTimeSeconds : 0
    }

    /// Green in the assured zone, orange between assured and limit, red past the limit.
    var statusColor: Color {
        if state.progress >= 1.0 { return .red }
        if state.progress >= assuredRatio { return .orange }
        return .green
    }
}

private func formatElapsed(_ seconds: TimeInterval, showHours: Bool = true) -> String {
    let hours = Int(seconds) / 3600
    let minutes = (Int(seconds) % 3600) / 60
    let secs = Int(seconds) % 60
    return showHours
        ? String(format: "%02d:%02d:%02d", hours, minutes, secs)
        : String(format: "%02d:%02d", hours * 60 + minutes, secs)
}

/// Amber "paused" pill.
private struct PausedPill: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "pause.fill")
                .font(.system(size: 9, weight: .bold))
            Text("PAUSED")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.5)
        }
        .foregroundStyle(.yellow)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.yellow.opacity(0.18), in: Capsule())
    }
}

// MARK: - Lock Screen View
struct LockScreenView: View {
    let context: ActivityViewContext<HOTActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Context strip, same as the in-app timer card
            HStack(spacing: 6) {
                ContextPill(systemImage: context.weatherSymbol, tint: WeatherStyle.tint, text: context.state.weatherCondition)
                    .layoutPriority(-1)
                ContextPill(systemImage: "thermometer.medium", tint: WeatherStyle.tint, text: context.temperatureText)
                ContextPill(systemImage: "drop.fill", tint: context.fluidColor, text: context.fluidText)
                if context.state.flapsExtended {
                    ContextPill(systemImage: "chevron.down.right.2", tint: .orange, text: "\u{00D7}0.76", emphasized: true)
                }
                if !context.state.isRunning {
                    PausedPill()
                }
            }

            // Progress bar
            ProgressBarView(context: context)

            // Time row
            HStack(alignment: .top) {
                timeColumn(label: "Elapsed", tint: .secondary, zulu: nil, value: formatElapsed(context.state.elapsedSeconds), alignment: .leading)
                Spacer()
                timeColumn(label: "Assured", tint: .green, zulu: context.state.assuredTimeZulu, value: nil, alignment: .center)
                Spacer()
                timeColumn(label: "Limit", tint: .orange, zulu: context.state.limitTimeZulu, value: nil, alignment: .trailing)
            }
        }
        .padding()
        .activityBackgroundTint(Color.black.opacity(0.8))
    }

    /// Label on top, then either a big value (elapsed) or a big Zulu time (assured / limit).
    private func timeColumn(label: String, tint: Color, zulu: String?, value: String?, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 3) {
            StatLabel(text: label, tint: tint)
            Text(value ?? zulu ?? "")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(tint == .secondary ? Color.primary : tint)
                .lineLimit(1)
        }
    }
}

// MARK: - Progress Bar View
struct ProgressBarView: View {
    let context: ActivityViewContext<HOTActivityAttributes>

    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let barHeight = geometry.size.height
            let assuredRatio = context.assuredRatio
            let greenWidth = totalWidth * assuredRatio
            let orangeWidth = totalWidth * (1.0 - assuredRatio)
            let progress = min(context.state.progress, 1.0) // Cap at 100% (limit)
            let atLimit = context.state.progress >= 1.0
            let indicatorWidth: CGFloat = barHeight // Same as height for a square/round shape that covers capsule rounding

            ZStack(alignment: .leading) {
                // Background track
                HStack(spacing: 0) {
                    if atLimit {
                        // Entire background becomes red at limit
                        Rectangle()
                            .fill(Color.red.opacity(0.3))
                    } else {
                        // Green zone (assured)
                        Rectangle()
                            .fill(Color.green.opacity(0.3))
                            .frame(width: greenWidth)

                        // Orange zone (between assured and limit)
                        Rectangle()
                            .fill(Color.orange.opacity(0.3))
                            .frame(width: orangeWidth)
                    }
                }
                .clipShape(Capsule())

                // Progress fill
                if atLimit {
                    // Entire bar is red when at or past limit
                    Capsule()
                        .fill(Color.red)
                } else {
                    HStack(spacing: 0) {
                        if progress <= assuredRatio {
                            // Still in green zone
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: totalWidth * progress)
                        } else {
                            // In orange zone
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: greenWidth)
                            Rectangle()
                                .fill(Color.orange)
                                .frame(width: totalWidth * (progress - assuredRatio))
                        }
                    }
                    .clipShape(Capsule())
                }

                // Current position indicator (hidden when at limit)
                if !atLimit {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white)
                        .frame(width: indicatorWidth, height: barHeight + 4)
                        .offset(x: totalWidth * progress - indicatorWidth / 2)
                }
            }
        }
        .frame(height: 12)
    }
}

// MARK: - Dynamic Island Views

struct CompactLeadingView: View {
    let context: ActivityViewContext<HOTActivityAttributes>

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: context.weatherSymbol)
                .foregroundStyle(WeatherStyle.tint)
            Image(systemName: "drop.fill")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(context.fluidColor)
            Text(HOTActivityAttributes.fluidTypeRoman(context.state.fluidType))
                .font(.system(.caption, design: .rounded).weight(.bold))
        }
    }
}

struct CompactTrailingView: View {
    let context: ActivityViewContext<HOTActivityAttributes>

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(context.statusColor)
                .frame(width: 8, height: 8)
            Text(context.state.limitTimeZulu)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .monospacedDigit()
        }
    }
}

struct MinimalView: View {
    let context: ActivityViewContext<HOTActivityAttributes>

    var body: some View {
        Image(systemName: context.weatherSymbol)
            .foregroundStyle(context.state.progress >= context.assuredRatio ? context.statusColor : WeatherStyle.tint)
    }
}

struct ExpandedLeadingView: View {
    let context: ActivityViewContext<HOTActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: context.weatherSymbol)
                .font(.title2)
                .foregroundStyle(WeatherStyle.tint)
                .symbolRenderingMode(.hierarchical)

            Text(context.temperatureText)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.leading, 6)
    }
}

struct ExpandedTrailingView: View {
    let context: ActivityViewContext<HOTActivityAttributes>

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            ContextPill(systemImage: "drop.fill", tint: context.fluidColor, text: context.fluidText)
            if context.state.flapsExtended {
                ContextPill(systemImage: "chevron.down.right.2", tint: .orange, text: "\u{00D7}0.76", emphasized: true)
            }
        }
        .padding(.trailing, 6)
    }
}

struct ExpandedCenterView: View {
    let context: ActivityViewContext<HOTActivityAttributes>

    var body: some View {
        VStack(spacing: 4) {
            Text(context.state.weatherCondition)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .lineLimit(1)

            if !context.state.isRunning {
                PausedPill()
            }
        }
    }
}

struct ExpandedBottomView: View {
    let context: ActivityViewContext<HOTActivityAttributes>

    var body: some View {
        VStack(spacing: 8) {
            // Mini progress bar
            GeometryReader { geometry in
                let progress = min(context.state.progress, 1.0)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.3))

                    Capsule()
                        .fill(context.statusColor)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 6)

            // Times
            HStack(alignment: .top) {
                miniColumn(label: "Assured", tint: .green, value: context.state.assuredTimeZulu, alignment: .leading)
                Spacer()
                miniColumn(label: "Elapsed", tint: .secondary, value: formatElapsed(context.state.elapsedSeconds, showHours: false), alignment: .center)
                Spacer()
                miniColumn(label: "Limit", tint: .orange, value: context.state.limitTimeZulu, alignment: .trailing)
            }
            .padding(.horizontal, 6)
        }
    }

    private func miniColumn(label: String, tint: Color, value: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            StatLabel(text: label, tint: tint)
            Text(value)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(tint == .secondary ? Color.primary : tint)
        }
    }
}

// MARK: - Preview Sample States

private enum PreviewStates {
    /// Green zone - early in holdover, running
    static let greenRunning = HOTActivityAttributes.ContentState(
        isRunning: true,
        elapsedSeconds: 480,
        assuredTimeZulu: "15:45z",
        limitTimeZulu: "15:53z",
        progress: 0.31,
        fluidType: 2,
        fluidPercentage: 75,
        waterPercentage: 25,
        precipitationType: "Light Snow",
        temperature: -5,
        temperatureUnit: "C",
        flapsExtended: false,
        assuredTimeSeconds: 18 * 60,
        limitTimeSeconds: 26 * 60,
        weatherCondition: "Light Freezing Rain"
    )

    /// Orange zone - past assured, approaching limit
    static let orangeRunning = HOTActivityAttributes.ContentState(
        isRunning: true,
        elapsedSeconds: 1200,
        assuredTimeZulu: "15:37z",
        limitTimeZulu: "15:53z",
        progress: 0.77,
        fluidType: 4,
        fluidPercentage: 50,
        waterPercentage: 50,
        precipitationType: "Moderate Snow",
        temperature: -12,
        temperatureUnit: "C",
        flapsExtended: true,
        assuredTimeSeconds: 18 * 60,
        limitTimeSeconds: 26 * 60,
        weatherCondition: "Snow, Snow Grains or Snow Pellets - Moderate"
    )

    /// Red zone - past limit, expired
    static let redExpired = HOTActivityAttributes.ContentState(
        isRunning: true,
        elapsedSeconds: 1620,
        assuredTimeZulu: "15:37z",
        limitTimeZulu: "15:45z",
        progress: 1.15,
        fluidType: 1,
        fluidPercentage: 100,
        waterPercentage: 0,
        precipitationType: "Freezing Drizzle",
        temperature: -3,
        temperatureUnit: "C",
        flapsExtended: false,
        assuredTimeSeconds: 15 * 60,
        limitTimeSeconds: 22 * 60,
        weatherCondition: "Freezing Drizzle"
    )

    /// Paused state
    static let paused = HOTActivityAttributes.ContentState(
        isRunning: false,
        elapsedSeconds: 900,
        assuredTimeZulu: "15:45z",
        limitTimeZulu: "15:53z",
        progress: 0.58,
        fluidType: 3,
        fluidPercentage: 75,
        waterPercentage: 25,
        precipitationType: "Light Rain",
        temperature: 0,
        temperatureUnit: "C",
        flapsExtended: true,
        assuredTimeSeconds: 18 * 60,
        limitTimeSeconds: 26 * 60,
        weatherCondition: "Rain on Cold Soaked Wing"
    )

    static let attributes = HOTActivityAttributes(timerStartTime: Date())
}

// MARK: - Lock Screen Previews

#Preview("Lock Screen - Green (Running)", as: .content, using: PreviewStates.attributes) {
    HOTLiveActivityWidget()
} contentStates: {
    PreviewStates.greenRunning
}

#Preview("Lock Screen - Orange (Caution)", as: .content, using: PreviewStates.attributes) {
    HOTLiveActivityWidget()
} contentStates: {
    PreviewStates.orangeRunning
}

#Preview("Lock Screen - Red (Expired)", as: .content, using: PreviewStates.attributes) {
    HOTLiveActivityWidget()
} contentStates: {
    PreviewStates.redExpired
}

#Preview("Lock Screen - Paused", as: .content, using: PreviewStates.attributes) {
    HOTLiveActivityWidget()
} contentStates: {
    PreviewStates.paused
}

// MARK: - Dynamic Island Expanded Previews

#Preview("DI Expanded - Green", as: .dynamicIsland(.expanded), using: PreviewStates.attributes) {
    HOTLiveActivityWidget()
} contentStates: {
    PreviewStates.greenRunning
}

#Preview("DI Expanded - Orange", as: .dynamicIsland(.expanded), using: PreviewStates.attributes) {
    HOTLiveActivityWidget()
} contentStates: {
    PreviewStates.orangeRunning
}

#Preview("DI Expanded - Expired", as: .dynamicIsland(.expanded), using: PreviewStates.attributes) {
    HOTLiveActivityWidget()
} contentStates: {
    PreviewStates.redExpired
}

#Preview("DI Expanded - Paused", as: .dynamicIsland(.expanded), using: PreviewStates.attributes) {
    HOTLiveActivityWidget()
} contentStates: {
    PreviewStates.paused
}

// MARK: - Dynamic Island Compact Previews

#Preview("DI Compact - Green", as: .dynamicIsland(.compact), using: PreviewStates.attributes) {
    HOTLiveActivityWidget()
} contentStates: {
    PreviewStates.greenRunning
}

#Preview("DI Compact - Orange", as: .dynamicIsland(.compact), using: PreviewStates.attributes) {
    HOTLiveActivityWidget()
} contentStates: {
    PreviewStates.orangeRunning
}

#Preview("DI Compact - Expired", as: .dynamicIsland(.compact), using: PreviewStates.attributes) {
    HOTLiveActivityWidget()
} contentStates: {
    PreviewStates.redExpired
}

// MARK: - Dynamic Island Minimal Previews

#Preview("DI Minimal - Green", as: .dynamicIsland(.minimal), using: PreviewStates.attributes) {
    HOTLiveActivityWidget()
} contentStates: {
    PreviewStates.greenRunning
}

#Preview("DI Minimal - Orange", as: .dynamicIsland(.minimal), using: PreviewStates.attributes) {
    HOTLiveActivityWidget()
} contentStates: {
    PreviewStates.orangeRunning
}

#Preview("DI Minimal - Expired", as: .dynamicIsland(.minimal), using: PreviewStates.attributes) {
    HOTLiveActivityWidget()
} contentStates: {
    PreviewStates.redExpired
}
