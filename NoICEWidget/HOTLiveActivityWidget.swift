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

// MARK: - Lock Screen View
struct LockScreenView: View {
    let context: ActivityViewContext<HOTActivityAttributes>

    var body: some View {
        VStack(spacing: 8) {
            // Header row
            HStack {
                // Weather icon and condition
                HStack(spacing: 6) {
                    Image(systemName: HOTActivityAttributes.sfSymbolForPrecipitation(context.state.precipitationType))
                        .font(.title2)
                        .foregroundStyle(.cyan)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.weatherCondition)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(2)

                        Text("\(Int(context.state.temperature))\u{00B0}\(context.state.temperatureUnit)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Fluid type badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Type \(HOTActivityAttributes.fluidTypeRoman(context.state.fluidType))")
                        .font(.caption)
                        .fontWeight(.semibold)

                    Text("(\(Int(context.state.fluidPercentage))/\(Int(context.state.waterPercentage)))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(fluidColor.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 6))

                // Flaps indicator
                Image(systemName: context.state.flapsExtended ? "chevron.down.right.2" : "chevron.forward.2")
                    .font(.title2)
                    .foregroundStyle(context.state.flapsExtended ? .orange : .white)
            }

            // Progress bar
            ProgressBarView(context: context)

            // Time row
            HStack {
                // Elapsed time
                VStack(alignment: .leading, spacing: 2) {
                    Text("Elapsed")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(formatElapsed(context.state.elapsedSeconds))
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                }

                Spacer()

                // Assured time
                VStack(alignment: .center, spacing: 2) {
                    Text("Assured")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(context.state.assuredTimeZulu)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundStyle(.green)
                }

                Spacer()

                // Limit time
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Limit")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(context.state.limitTimeZulu)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                }
            }

            // Status indicator
            if !context.state.isRunning {
                Text("PAUSED")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.yellow)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .activityBackgroundTint(Color.black.opacity(0.8))
    }

    private var fluidColor: Color {
        colorForFluidType(context.state.fluidType)
    }

    private func formatElapsed(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
}

// MARK: - Progress Bar View
struct ProgressBarView: View {
    let context: ActivityViewContext<HOTActivityAttributes>

    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let barHeight = geometry.size.height
            let assuredRatio = context.state.assuredTimeSeconds / context.state.limitTimeSeconds
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
            Image(systemName: HOTActivityAttributes.sfSymbolForPrecipitation(context.state.precipitationType))
                .foregroundStyle(.cyan)
            Text(HOTActivityAttributes.fluidTypeRoman(context.state.fluidType))
                .font(.caption)
                .fontWeight(.bold)
        }
    }
}

struct CompactTrailingView: View {
    let context: ActivityViewContext<HOTActivityAttributes>

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(context.state.limitTimeZulu)
                .font(.caption)
                .fontWeight(.medium)
                .monospacedDigit()
        }
    }

    private var statusColor: Color {
        if context.state.progress >= 1.0 {
            return .red
        } else if context.state.progress >= context.state.assuredTimeSeconds / context.state.limitTimeSeconds {
            return .orange
        }
        return .green
    }
}

struct MinimalView: View {
    let context: ActivityViewContext<HOTActivityAttributes>

    var body: some View {
        Image(systemName: HOTActivityAttributes.sfSymbolForPrecipitation(context.state.precipitationType))
            .foregroundStyle(statusColor)
    }

    private var statusColor: Color {
        if context.state.progress >= 1.0 {
            return .red
        } else if context.state.progress >= context.state.assuredTimeSeconds / context.state.limitTimeSeconds {
            return .orange
        }
        return .cyan
    }
}

struct ExpandedLeadingView: View {
    let context: ActivityViewContext<HOTActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: HOTActivityAttributes.sfSymbolForPrecipitation(context.state.precipitationType))
                .font(.title2)
                .foregroundStyle(.cyan)

            Text("\(Int(context.state.temperature))\u{00B0}\(context.state.temperatureUnit)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct ExpandedTrailingView: View {
    let context: ActivityViewContext<HOTActivityAttributes>

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("Type \(HOTActivityAttributes.fluidTypeRoman(context.state.fluidType))")
                .font(.caption)
                .fontWeight(.semibold)

            Text("\(Int(context.state.fluidPercentage))/\(Int(context.state.waterPercentage))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct ExpandedCenterView: View {
    let context: ActivityViewContext<HOTActivityAttributes>

    var body: some View {
        VStack(spacing: 2) {
            Text(context.state.weatherCondition)
                .font(.caption)
                .fontWeight(.medium)

            if !context.state.isRunning {
                Text("PAUSED")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
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
                let progress = min(context.state.progress, 1.2)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.3))

                    Capsule()
                        .fill(progressColor)
                        .frame(width: geometry.size.width * min(progress, 1.0))
                }
            }
            .frame(height: 6)

            // Times
            HStack {
                Text(context.state.assuredTimeZulu)
                    .font(.caption2)
                    .foregroundStyle(.green)

                Spacer()

                Text(formatElapsed(context.state.elapsedSeconds))
                    .font(.caption2)
                    .monospacedDigit()

                Spacer()

                Text(context.state.limitTimeZulu)
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var progressColor: Color {
        if context.state.progress >= 1.0 {
            return .red
        } else if context.state.progress >= context.state.assuredTimeSeconds / context.state.limitTimeSeconds {
            return .orange
        }
        return .green
    }

    private func formatElapsed(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
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
