import SwiftUI
import Combine

// MARK: - Color Names
struct ColorNamer {
    static func name(for hue: Double) -> String {
        let deg = hue * 360
        switch deg {
        case 0..<8:     return "Crimson"
        case 8..<18:    return "Scarlet"
        case 18..<30:   return "Red Orange"
        case 30..<45:   return "Vermillion"
        case 45..<55:   return "Tangerine"
        case 55..<65:   return "Amber"
        case 65..<75:   return "Golden"
        case 75..<85:   return "Yellow"
        case 85..<95:   return "Citrus"
        case 95..<110:  return "Chartreuse"
        case 110..<130: return "Lime"
        case 130..<150: return "Emerald"
        case 150..<165: return "Jade"
        case 165..<175: return "Mint"
        case 175..<185: return "Aquamarine"
        case 185..<195: return "Cyan"
        case 195..<210: return "Cerulean"
        case 210..<225: return "Sky Blue"
        case 225..<240: return "Cobalt"
        case 240..<255: return "Indigo"
        case 255..<270: return "Sapphire"
        case 270..<285: return "Violet"
        case 285..<295: return "Amethyst"
        case 295..<310: return "Purple"
        case 310..<325: return "Magenta"
        case 325..<340: return "Fuchsia"
        case 340..<352: return "Rose"
        default:        return "Crimson"
        }
    }
}

// MARK: - Time of Day Theme
struct TimeOfDayTheme {
    let backgroundTop: Color
    let backgroundBottom: Color
    let label: String

    static func from(date: Date) -> TimeOfDayTheme {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 0..<5:
            return TimeOfDayTheme(
                backgroundTop:    Color(red: 0.04, green: 0.03, blue: 0.12),
                backgroundBottom: Color(red: 0.02, green: 0.02, blue: 0.08),
                label: "midnight")
        case 5..<7:
            return TimeOfDayTheme(
                backgroundTop:    Color(red: 0.18, green: 0.08, blue: 0.20),
                backgroundBottom: Color(red: 0.08, green: 0.04, blue: 0.12),
                label: "dawn")
        case 7..<10:
            return TimeOfDayTheme(
                backgroundTop:    Color(red: 0.35, green: 0.18, blue: 0.06),
                backgroundBottom: Color(red: 0.15, green: 0.08, blue: 0.03),
                label: "sunrise")
        case 10..<13:
            return TimeOfDayTheme(
                backgroundTop:    Color(red: 0.04, green: 0.15, blue: 0.32),
                backgroundBottom: Color(red: 0.02, green: 0.07, blue: 0.15),
                label: "morning")
        case 13..<16:
            return TimeOfDayTheme(
                backgroundTop:    Color(red: 0.02, green: 0.18, blue: 0.38),
                backgroundBottom: Color(red: 0.01, green: 0.08, blue: 0.18),
                label: "midday")
        case 16..<18:
            return TimeOfDayTheme(
                backgroundTop:    Color(red: 0.32, green: 0.15, blue: 0.04),
                backgroundBottom: Color(red: 0.15, green: 0.07, blue: 0.02),
                label: "afternoon")
        case 18..<20:
            return TimeOfDayTheme(
                backgroundTop:    Color(red: 0.38, green: 0.12, blue: 0.08),
                backgroundBottom: Color(red: 0.18, green: 0.05, blue: 0.06),
                label: "sunset")
        case 20..<22:
            return TimeOfDayTheme(
                backgroundTop:    Color(red: 0.10, green: 0.05, blue: 0.20),
                backgroundBottom: Color(red: 0.05, green: 0.02, blue: 0.10),
                label: "dusk")
        default:
            return TimeOfDayTheme(
                backgroundTop:    Color(red: 0.05, green: 0.03, blue: 0.12),
                backgroundBottom: Color(red: 0.02, green: 0.02, blue: 0.07),
                label: "night")
        }
    }
}

// MARK: - Time → Color Mapping
struct TimeColor {
    let hue: Double
    let saturation: Double
    let brightness: Double

    var color: Color {
        Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    var secondaryColor: Color {
        Color(hue: (hue + 0.5).truncatingRemainder(dividingBy: 1.0),
              saturation: saturation * 0.3,
              brightness: 0.15)
    }

    var name: String { ColorNamer.name(for: hue) }

    static func from(date: Date) -> TimeColor {
        let cal    = Calendar.current
        let hour   = Double(cal.component(.hour,   from: date)).truncatingRemainder(dividingBy: 12)
        let minute = Double(cal.component(.minute, from: date))
        let second = Double(cal.component(.second, from: date))

        let hue        = (hour * 60 + minute) / 720.0
        let saturation = 0.55 + (minute / 60.0) * 0.45
        let pulse      = sin(second / 60.0 * .pi)
        let brightness = 0.80 + pulse * 0.10

        return TimeColor(hue: hue, saturation: saturation, brightness: brightness)
    }
}

// MARK: - Palette Snapshot
struct PaletteSnapshot: Identifiable {
    let id         = UUID()
    let hue:        Double
    let saturation: Double
    let brightness: Double
    let name:       String
    let time:       Date

    var color: Color {
        Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "hh:mm a"
        return f.string(from: time)
    }
}

// MARK: - Timer Color Preset
struct TimerPreset: Identifiable {
    let id      = UUID()
    let name:    String
    let minutes: Int
    let hue:     Double

    var color: Color { Color(hue: hue, saturation: 0.85, brightness: 0.95) }

    static let presets: [TimerPreset] = [
        TimerPreset(name: "Focus",  minutes: 25, hue: 0.62),
        TimerPreset(name: "Short",  minutes: 10, hue: 0.38),
        TimerPreset(name: "Long",   minutes: 50, hue: 0.75),
        TimerPreset(name: "Sprint", minutes: 5,  hue: 0.08),
        TimerPreset(name: "Rest",   minutes: 15, hue: 0.50),
    ]
}

// MARK: - Clock ViewModel
class ClockViewModel: ObservableObject {
    @Published var currentDate = Date()
    @Published var timeColor   = TimeColor.from(date: Date())
    @Published var theme       = TimeOfDayTheme.from(date: Date())
    @Published var colorTrail: [TimeColor]       = []
    @Published var snapshots:  [PaletteSnapshot] = []

    private var timer: AnyCancellable?
    private let trailLength = 40

    init() {
        // Seed trail with recent history
        let now = Date()
        for i in stride(from: trailLength, through: 1, by: -1) {
            let past = now.addingTimeInterval(Double(-i))
            colorTrail.append(TimeColor.from(date: past))
        }
        start()
    }

    func start() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                guard let self = self else { return }
                self.currentDate = date
                let newColor = TimeColor.from(date: date)
                self.colorTrail.append(newColor)
                if self.colorTrail.count > self.trailLength {
                    self.colorTrail.removeFirst()
                }
                self.timeColor = newColor
                self.theme     = TimeOfDayTheme.from(date: date)
            }
    }

    func saveSnapshot() {
        let snap = PaletteSnapshot(
            hue:        timeColor.hue,
            saturation: timeColor.saturation,
            brightness: timeColor.brightness,
            name:       timeColor.name,
            time:       currentDate
        )
        snapshots.insert(snap, at: 0)
    }

    var hourAngle: Double {
        let cal    = Calendar.current
        let hour   = Double(cal.component(.hour,   from: currentDate)).truncatingRemainder(dividingBy: 12)
        let minute = Double(cal.component(.minute, from: currentDate))
        return (hour * 60 + minute) / 720.0 * 360.0 - 90
    }

    var minuteAngle: Double {
        let cal    = Calendar.current
        let minute = Double(cal.component(.minute, from: currentDate))
        let second = Double(cal.component(.second, from: currentDate))
        return (minute * 60 + second) / 3600.0 * 360.0 - 90
    }

    var secondAngle: Double {
        let cal    = Calendar.current
        let second = Double(cal.component(.second, from: currentDate))
        return second / 60.0 * 360.0 - 90
    }

    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "hh:mm:ss"
        return f.string(from: currentDate)
    }

    var periodString: String {
        let f = DateFormatter()
        f.dateFormat = "a"
        return f.string(from: currentDate)
    }
}

// MARK: - Timer ViewModel
class TimerViewModel: ObservableObject {
    @Published var totalSeconds:     Int         = 60
    @Published var remainingSeconds: Int         = 60
    @Published var isRunning:        Bool        = false
    @Published var isFinished:       Bool        = false
    @Published var inputMinutes:     Int         = 1
    @Published var inputSeconds:     Int         = 0
    @Published var selectedPreset:   TimerPreset? = nil

    private var timer: AnyCancellable?

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(remainingSeconds) / Double(totalSeconds)
    }

    // Gradient burn — warm when full, cool when nearly empty
    var burnBackgroundTop: Color {
        let t = progress
        return Color(
            red:   0.30 * t + 0.02 * (1 - t),
            green: 0.08 * t + 0.06 * (1 - t),
            blue:  0.04 * t + 0.22 * (1 - t)
        )
    }

    var burnBackgroundBottom: Color {
        let t = progress
        return Color(
            red:   0.12 * t + 0.01 * (1 - t),
            green: 0.04 * t + 0.03 * (1 - t),
            blue:  0.02 * t + 0.12 * (1 - t)
        )
    }

    var progressColor: Color {
        if let preset = selectedPreset {
            return Color(hue: preset.hue,
                         saturation: 0.5 + progress * 0.5,
                         brightness: 0.6 + progress * 0.3)
        }
        return Color(hue: progress * 0.35, saturation: 0.8, brightness: 0.9)
    }

    var displayString: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    func applyPreset(_ preset: TimerPreset) {
        selectedPreset = preset
        inputMinutes   = preset.minutes
        inputSeconds   = 0
        set()
    }

    func set() {
        totalSeconds     = inputMinutes * 60 + inputSeconds
        remainingSeconds = totalSeconds
        isFinished       = false
    }

    func toggle() { isRunning ? pause() : play() }

    func play() {
        guard remainingSeconds > 0 else { return }
        isRunning  = true
        isFinished = false
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                } else {
                    self.isRunning  = false
                    self.isFinished = true
                    self.timer?.cancel()
                }
            }
    }

    func pause() {
        isRunning = false
        timer?.cancel()
    }

    func reset() {
        pause()
        remainingSeconds = totalSeconds
        isFinished       = false
    }
}
