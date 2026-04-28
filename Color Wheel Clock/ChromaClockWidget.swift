import WidgetKit
import SwiftUI

// MARK: - Widget Timeline Entry
struct ChromaEntry: TimelineEntry {
    let date:       Date
    let hue:        Double
    let saturation: Double
    let brightness: Double
    let colorName:  String
    let timeString: String
    let themeName:  String

    var color: Color { Color(hue: hue, saturation: saturation, brightness: brightness) }

    static func from(date: Date) -> ChromaEntry {
        let cal    = Calendar.current
        let hour   = Double(cal.component(.hour,   from: date)).truncatingRemainder(dividingBy: 12)
        let minute = Double(cal.component(.minute, from: date))
        let second = Double(cal.component(.second, from: date))

        let hue        = (hour * 60 + minute) / 720.0
        let saturation = 0.55 + (minute / 60.0) * 0.45
        let brightness = 0.80 + sin(second / 60.0 * .pi) * 0.10

        let colorName = ChromaWidgetColorNamer.name(for: hue)

        let f = DateFormatter()
        f.dateFormat = "hh:mm"
        let timeString = f.string(from: date)

        let h = cal.component(.hour, from: date)
        let themeName: String
        switch h {
        case 0..<5:   themeName = "midnight"
        case 5..<7:   themeName = "dawn"
        case 7..<10:  themeName = "sunrise"
        case 10..<13: themeName = "morning"
        case 13..<16: themeName = "midday"
        case 16..<18: themeName = "afternoon"
        case 18..<20: themeName = "sunset"
        case 20..<22: themeName = "dusk"
        default:      themeName = "night"
        }

        return ChromaEntry(date: date, hue: hue, saturation: saturation,
                           brightness: brightness, colorName: colorName,
                           timeString: timeString, themeName: themeName)
    }
}

// MARK: - Color Namer (self-contained for widget)
struct ChromaWidgetColorNamer {
    static func name(for hue: Double) -> String {
        let deg = hue * 360
        switch deg {
        case 0..<18:    return "Crimson"
        case 18..<45:   return "Vermillion"
        case 45..<65:   return "Amber"
        case 65..<95:   return "Yellow"
        case 95..<130:  return "Chartreuse"
        case 130..<165: return "Emerald"
        case 165..<195: return "Cyan"
        case 195..<225: return "Sky Blue"
        case 225..<255: return "Cobalt"
        case 255..<285: return "Violet"
        case 285..<310: return "Purple"
        case 310..<340: return "Magenta"
        default:        return "Rose"
        }
    }
}

// MARK: - Timeline Provider
struct ChromaProvider: TimelineProvider {
    func placeholder(in context: Context) -> ChromaEntry {
        ChromaEntry.from(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (ChromaEntry) -> Void) {
        completion(ChromaEntry.from(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChromaEntry>) -> Void) {
        let now    = Date()
        let cal    = Calendar.current
        var entries: [ChromaEntry] = []

        // Generate one entry per minute for the next hour
        for i in 0..<60 {
            if let date = cal.date(byAdding: .minute, value: i, to: now) {
                entries.append(ChromaEntry.from(date: date))
            }
        }

        let nextHour = cal.date(byAdding: .hour, value: 1, to: now) ?? now
        let timeline = Timeline(entries: entries, policy: .after(nextHour))
        completion(timeline)
    }
}

// MARK: - Small Widget View (home screen)
struct ChromaSmallWidgetView: View {
    var entry: ChromaEntry

    var body: some View {
        ZStack {
            // Background — hue-tinted dark
            Color(hue: entry.hue, saturation: 0.40, brightness: 0.12)

            VStack(spacing: 6) {
                // Mini color wheel ring
                ZStack {
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: spectrumColors()),
                                center: .center
                            ),
                            lineWidth: 7
                        )
                        .frame(width: 64, height: 64)

                    // Current position dot
                    Circle()
                        .fill(entry.color)
                        .frame(width: 8, height: 8)
                        .offset(y: -32)
                        .rotationEffect(.degrees(entry.hue * 360 - 90))

                    VStack(spacing: 1) {
                        Text(entry.timeString)
                            .font(.system(size: 14, weight: .thin, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }

                Text(entry.colorName)
                    .font(.system(size: 9, weight: .light, design: .monospaced))
                    .foregroundColor(entry.color)

                Text(entry.themeName)
                    .font(.system(size: 7, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.30))
                    .tracking(1)
                    .textCase(.uppercase)
            }
        }
    }

    func spectrumColors() -> [Color] {
        stride(from: 0.0, to: 1.0, by: 0.05).map {
            Color(hue: $0, saturation: 0.85, brightness: 0.90)
        }
    }
}

// MARK: - Rectangular Lock Screen Widget
struct ChromaLockRectangularView: View {
    var entry: ChromaEntry

    var body: some View {
        HStack(spacing: 10) {
            // Color swatch
            RoundedRectangle(cornerRadius: 5)
                .fill(entry.color)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.timeString)
                    .font(.system(size: 16, weight: .thin, design: .monospaced))
                    .foregroundColor(.white)
                Text(entry.colorName)
                    .font(.system(size: 10, weight: .light, design: .monospaced))
                    .foregroundColor(entry.color)
            }

            Spacer()

            Text(entry.themeName)
                .font(.system(size: 8, weight: .light, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1)
                .textCase(.uppercase)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Circular Lock Screen Widget
struct ChromaLockCircularView: View {
    var entry: ChromaEntry

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: spectrumColors()),
                        center: .center
                    ),
                    lineWidth: 4
                )

            VStack(spacing: 1) {
                Text(entry.timeString)
                    .font(.system(size: 11, weight: .thin, design: .monospaced))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.6)
            }
        }
        .padding(4)
    }

    func spectrumColors() -> [Color] {
        stride(from: 0.0, to: 1.0, by: 0.05).map {
            Color(hue: $0, saturation: 0.85, brightness: 0.90)
        }
    }
}

// MARK: - Inline Lock Screen Widget
struct ChromaLockInlineView: View {
    var entry: ChromaEntry

    var body: some View {
        Label {
            Text("\(entry.timeString) · \(entry.colorName)")
                .font(.system(size: 12, weight: .light, design: .monospaced))
        } icon: {
            Circle().fill(entry.color).frame(width: 10, height: 10)
        }
    }
}

// MARK: - Widget Entry View (routes to correct size)
struct ChromaWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: ChromaEntry

    var body: some View {
        switch family {
        case .systemSmall:
            ChromaSmallWidgetView(entry: entry)
        case .accessoryRectangular:
            ChromaLockRectangularView(entry: entry)
        case .accessoryCircular:
            ChromaLockCircularView(entry: entry)
        case .accessoryInline:
            ChromaLockInlineView(entry: entry)
        default:
            ChromaSmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration

struct ChromaClockWidget: Widget {
    let kind = "ChromaClockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ChromaProvider()) { entry in
            ChromaWidgetEntryView(entry: entry)
                .containerBackground(
                    Color(hue: entry.hue, saturation: 0.35, brightness: 0.10),
                    for: .widget
                )
        }
        .configurationDisplayName("Chroma Clock")
        .description("See the current time as a color.")
        .supportedFamilies([
            .systemSmall,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    ChromaClockWidget()
} timeline: {
    ChromaEntry.from(date: Date())
}

#Preview(as: .accessoryRectangular) {
    ChromaClockWidget()
} timeline: {
    ChromaEntry.from(date: Date())
}

#Preview(as: .accessoryCircular) {
    ChromaClockWidget()
} timeline: {
    ChromaEntry.from(date: Date())
}
