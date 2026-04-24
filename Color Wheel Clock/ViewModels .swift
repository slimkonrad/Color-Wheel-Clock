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

    // Full list of named hues for alarm/preset pickers
    static let allNames: [(name: String, hue: Double)] = [
        ("Crimson", 0.00), ("Scarlet", 0.03), ("Vermillion", 0.06),
        ("Tangerine", 0.11), ("Amber", 0.14), ("Golden", 0.17),
        ("Yellow", 0.19), ("Chartreuse", 0.23), ("Lime", 0.28),
        ("Emerald", 0.35), ("Jade", 0.40), ("Mint", 0.44),
        ("Aquamarine", 0.46), ("Cyan", 0.50), ("Cerulean", 0.53),
        ("Sky Blue", 0.57), ("Cobalt", 0.61), ("Indigo", 0.65),
        ("Sapphire", 0.69), ("Violet", 0.73), ("Amethyst", 0.77),
        ("Purple", 0.81), ("Magenta", 0.85), ("Fuchsia", 0.88),
        ("Rose", 0.93)
    ]
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
            return TimeOfDayTheme(backgroundTop: Color(red:0.04,green:0.03,blue:0.12), backgroundBottom: Color(red:0.02,green:0.02,blue:0.08), label:"midnight")
        case 5..<7:
            return TimeOfDayTheme(backgroundTop: Color(red:0.18,green:0.08,blue:0.20), backgroundBottom: Color(red:0.08,green:0.04,blue:0.12), label:"dawn")
        case 7..<10:
            return TimeOfDayTheme(backgroundTop: Color(red:0.35,green:0.18,blue:0.06), backgroundBottom: Color(red:0.15,green:0.08,blue:0.03), label:"sunrise")
        case 10..<13:
            return TimeOfDayTheme(backgroundTop: Color(red:0.04,green:0.15,blue:0.32), backgroundBottom: Color(red:0.02,green:0.07,blue:0.15), label:"morning")
        case 13..<16:
            return TimeOfDayTheme(backgroundTop: Color(red:0.02,green:0.18,blue:0.38), backgroundBottom: Color(red:0.01,green:0.08,blue:0.18), label:"midday")
        case 16..<18:
            return TimeOfDayTheme(backgroundTop: Color(red:0.32,green:0.15,blue:0.04), backgroundBottom: Color(red:0.15,green:0.07,blue:0.02), label:"afternoon")
        case 18..<20:
            return TimeOfDayTheme(backgroundTop: Color(red:0.38,green:0.12,blue:0.08), backgroundBottom: Color(red:0.18,green:0.05,blue:0.06), label:"sunset")
        case 20..<22:
            return TimeOfDayTheme(backgroundTop: Color(red:0.10,green:0.05,blue:0.20), backgroundBottom: Color(red:0.05,green:0.02,blue:0.10), label:"dusk")
        default:
            return TimeOfDayTheme(backgroundTop: Color(red:0.05,green:0.03,blue:0.12), backgroundBottom: Color(red:0.02,green:0.02,blue:0.07), label:"night")
        }
    }
}

// MARK: - Time → Color
struct TimeColor {
    let hue: Double
    let saturation: Double
    let brightness: Double

    var color: Color { Color(hue: hue, saturation: saturation, brightness: brightness) }
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
    let id = UUID()
    let hue: Double; let saturation: Double; let brightness: Double
    let name: String; let time: Date
    var color: Color { Color(hue: hue, saturation: saturation, brightness: brightness) }
    var timeString: String {
        let f = DateFormatter(); f.dateFormat = "hh:mm a"; return f.string(from: time)
    }
}

// MARK: - Custom Timer Preset
struct TimerPreset: Identifiable, Codable {
    var id       = UUID()
    var name:    String
    var minutes: Int
    var seconds: Int
    var hue:     Double

    var color: Color { Color(hue: hue, saturation: 0.85, brightness: 0.95) }
    var totalSeconds: Int { minutes * 60 + seconds }

    static var defaults: [TimerPreset] = [
        TimerPreset(name: "Focus",  minutes: 25, seconds: 0, hue: 0.62),
        TimerPreset(name: "Short",  minutes: 10, seconds: 0, hue: 0.38),
        TimerPreset(name: "Long",   minutes: 50, seconds: 0, hue: 0.75),
        TimerPreset(name: "Sprint", minutes: 5,  seconds: 0, hue: 0.08),
        TimerPreset(name: "Rest",   minutes: 15, seconds: 0, hue: 0.50),
    ]
}

// MARK: - Alarm
struct Alarm: Identifiable, Codable {
    var id       = UUID()
    var hour:    Int
    var minute:  Int
    var label:   String
    var hue:     Double
    var enabled: Bool = true

    var color: Color { Color(hue: hue, saturation: 0.85, brightness: 0.95) }

    var timeString: String {
        let period = hour >= 12 ? "PM" : "AM"
        let h = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%d:%02d %@", h, minute, period)
    }

    // Hue that corresponds to this time on the clock color wheel
    var clockHue: Double {
        let h = Double(hour).truncatingRemainder(dividingBy: 12)
        return (h * 60 + Double(minute)) / 720.0
    }
}

// MARK: - Stopwatch Lap
struct StopwatchLap: Identifiable {
    let id      = UUID()
    let number: Int
    let elapsed: TimeInterval
    let split:   TimeInterval
    let hue:     Double
    var color: Color { Color(hue: hue, saturation: 0.85, brightness: 0.90) }

    var elapsedString: String { formatInterval(elapsed) }
    var splitString:   String { formatInterval(split) }

    private func formatInterval(_ t: TimeInterval) -> String {
        let mins  = Int(t) / 60
        let secs  = Int(t) % 60
        let cents = Int((t.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", mins, secs, cents)
    }
}

// MARK: - Breathing Phase
enum BreathingPhase: String {
    case inhale = "inhale"
    case hold   = "hold"
    case exhale = "exhale"
    case rest   = "rest"

    var duration: Double {
        switch self {
        case .inhale: return 4
        case .hold:   return 4
        case .exhale: return 6
        case .rest:   return 2
        }
    }

    var instruction: String {
        switch self {
        case .inhale: return "breathe in"
        case .hold:   return "hold"
        case .exhale: return "breathe out"
        case .rest:   return "rest"
        }
    }

    var targetScale: CGFloat {
        switch self {
        case .inhale: return 1.25
        case .hold:   return 1.25
        case .exhale: return 0.75
        case .rest:   return 0.75
        }
    }

    static let cycle: [BreathingPhase] = [.inhale, .hold, .exhale, .rest]
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
        let now = Date()
        for i in stride(from: trailLength, through: 1, by: -1) {
            colorTrail.append(TimeColor.from(date: now.addingTimeInterval(Double(-i))))
        }
        start()
    }

    func start() {
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            .sink { [weak self] date in
                guard let self = self else { return }
                self.currentDate = date
                let newColor = TimeColor.from(date: date)
                self.colorTrail.append(newColor)
                if self.colorTrail.count > self.trailLength { self.colorTrail.removeFirst() }
                self.timeColor = newColor
                self.theme     = TimeOfDayTheme.from(date: date)
            }
    }

    func saveSnapshot() {
        snapshots.insert(PaletteSnapshot(
            hue: timeColor.hue, saturation: timeColor.saturation,
            brightness: timeColor.brightness, name: timeColor.name, time: currentDate
        ), at: 0)
    }

    var hourAngle:   Double {
        let cal = Calendar.current
        let h = Double(cal.component(.hour,   from: currentDate)).truncatingRemainder(dividingBy: 12)
        let m = Double(cal.component(.minute, from: currentDate))
        return (h * 60 + m) / 720.0 * 360.0 - 90
    }
    var minuteAngle: Double {
        let cal = Calendar.current
        let m = Double(cal.component(.minute, from: currentDate))
        let s = Double(cal.component(.second, from: currentDate))
        return (m * 60 + s) / 3600.0 * 360.0 - 90
    }
    var secondAngle: Double {
        let s = Double(Calendar.current.component(.second, from: currentDate))
        return s / 60.0 * 360.0 - 90
    }
    var timeString:   String { let f = DateFormatter(); f.dateFormat = "hh:mm:ss"; return f.string(from: currentDate) }
    var periodString: String { let f = DateFormatter(); f.dateFormat = "a";        return f.string(from: currentDate) }
}

// MARK: - Timer ViewModel
class TimerViewModel: ObservableObject {
    @Published var totalSeconds:     Int          = 60
    @Published var remainingSeconds: Int          = 60
    @Published var isRunning:        Bool         = false
    @Published var isFinished:       Bool         = false
    @Published var inputMinutes:     Int          = 1
    @Published var inputSeconds:     Int          = 0
    @Published var selectedPreset:   TimerPreset? = nil
    @Published var presets:          [TimerPreset] = TimerPreset.defaults

    private var timer: AnyCancellable?

    var progress: Double { guard totalSeconds > 0 else { return 0 }; return Double(remainingSeconds) / Double(totalSeconds) }

    var burnBackgroundTop: Color {
        Color(red: 0.30*progress + 0.02*(1-progress), green: 0.08*progress + 0.06*(1-progress), blue: 0.04*progress + 0.22*(1-progress))
    }
    var burnBackgroundBottom: Color {
        Color(red: 0.12*progress + 0.01*(1-progress), green: 0.04*progress + 0.03*(1-progress), blue: 0.02*progress + 0.12*(1-progress))
    }
    var progressColor: Color {
        if let p = selectedPreset { return Color(hue: p.hue, saturation: 0.5 + progress*0.5, brightness: 0.6 + progress*0.3) }
        return Color(hue: progress * 0.35, saturation: 0.8, brightness: 0.9)
    }
    var displayString: String { String(format: "%02d:%02d", remainingSeconds/60, remainingSeconds%60) }

    func applyPreset(_ preset: TimerPreset) {
        selectedPreset = preset; inputMinutes = preset.minutes; inputSeconds = preset.seconds; set()
    }
    func set()    { totalSeconds = inputMinutes*60 + inputSeconds; remainingSeconds = totalSeconds; isFinished = false }
    func toggle() { isRunning ? pause() : play() }
    func play() {
        guard remainingSeconds > 0 else { return }
        isRunning = true; isFinished = false
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.remainingSeconds > 0 { self.remainingSeconds -= 1 }
                else { self.isRunning = false; self.isFinished = true; self.timer?.cancel() }
            }
    }
    func pause() { isRunning = false; timer?.cancel() }
    func reset()  { pause(); remainingSeconds = totalSeconds; isFinished = false }

    func addPreset(_ preset: TimerPreset) { presets.append(preset) }
    func deletePreset(at offsets: IndexSet) { presets.remove(atOffsets: offsets) }
}

// MARK: - Stopwatch ViewModel
class StopwatchViewModel: ObservableObject {
    @Published var elapsed:   TimeInterval = 0
    @Published var isRunning: Bool         = false
    @Published var laps:      [StopwatchLap] = []

    private var timer:     AnyCancellable?
    private var startDate: Date?
    private var accumulated: TimeInterval = 0
    private var lastLapTime: TimeInterval = 0

    var displayString: String {
        let mins  = Int(elapsed) / 60
        let secs  = Int(elapsed) % 60
        let cents = Int((elapsed.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", mins, secs, cents)
    }

    var currentHue: Double { (elapsed.truncatingRemainder(dividingBy: 60)) / 60.0 }
    var currentColor: Color { Color(hue: currentHue, saturation: 0.85, brightness: 0.92) }

    func toggle() { isRunning ? pause() : start() }

    func start() {
        startDate = Date(); isRunning = true
        timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                guard let self = self, let start = self.startDate else { return }
                self.elapsed = self.accumulated + Date().timeIntervalSince(start)
            }
    }

    func pause() {
        accumulated = elapsed; startDate = nil; isRunning = false; timer?.cancel()
    }

    func reset() {
        pause(); elapsed = 0; accumulated = 0; lastLapTime = 0; laps = []
    }

    func lap() {
        guard isRunning else { return }
        let split = elapsed - lastLapTime
        let lap = StopwatchLap(number: laps.count + 1, elapsed: elapsed, split: split,
                               hue: currentHue)
        laps.insert(lap, at: 0)
        lastLapTime = elapsed
    }
}

// MARK: - Alarm ViewModel
class AlarmViewModel: ObservableObject {
    @Published var alarms: [Alarm] = []
    @Published var firedAlarm: Alarm? = nil

    private var timer: AnyCancellable?

    init() { startChecking() }

    func startChecking() {
        timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
            .sink { [weak self] date in self?.checkAlarms(date: date) }
    }

    func checkAlarms(date: Date) {
        let cal = Calendar.current
        let h = cal.component(.hour,   from: date)
        let m = cal.component(.minute, from: date)
        for alarm in alarms where alarm.enabled {
            if alarm.hour == h && alarm.minute == m { firedAlarm = alarm }
        }
    }

    func addAlarm(_ alarm: Alarm) { alarms.append(alarm) }
    func deleteAlarm(at offsets: IndexSet) { alarms.remove(atOffsets: offsets) }
    func toggleAlarm(id: UUID) {
        if let i = alarms.firstIndex(where: { $0.id == id }) { alarms[i].enabled.toggle() }
    }
    func dismissFired() { firedAlarm = nil }
}

// MARK: - Breathing ViewModel
class BreathingViewModel: ObservableObject {
    @Published var phase:        BreathingPhase = .inhale
    @Published var phaseProgress: Double        = 0
    @Published var isRunning:    Bool           = false
    @Published var cycleCount:   Int            = 0
    @Published var currentHue:   Double         = 0.5

    private var timer:       AnyCancellable?
    private var phaseStart:  Date?
    private var phaseIndex:  Int = 0
    private let tickInterval: Double = 0.05

    var scale: CGFloat {
        switch phase {
        case .inhale: return 0.75 + CGFloat(phaseProgress) * 0.50
        case .hold:   return 1.25
        case .exhale: return 1.25 - CGFloat(phaseProgress) * 0.50
        case .rest:   return 0.75
        }
    }

    var color: Color { Color(hue: currentHue, saturation: 0.70, brightness: 0.90) }
    var ringColor: Color { Color(hue: (currentHue + 0.15).truncatingRemainder(dividingBy: 1), saturation: 0.60, brightness: 0.85) }

    func toggle() { isRunning ? stop() : start() }

    func start() {
        isRunning = true; phaseStart = Date(); phaseProgress = 0
        timer = Timer.publish(every: tickInterval, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    func stop() {
        isRunning = false; timer?.cancel()
        phaseIndex = 0; phase = .inhale; phaseProgress = 0; cycleCount = 0
    }

    private func tick() {
        guard let start = phaseStart else { return }
        let elapsed  = Date().timeIntervalSince(start)
        let duration = phase.duration
        phaseProgress = min(elapsed / duration, 1.0)

        // Hue drifts slowly through the spectrum as you breathe
        currentHue = (currentHue + 0.0003).truncatingRemainder(dividingBy: 1.0)

        if elapsed >= duration { advancePhase() }
    }

    private func advancePhase() {
        phaseIndex = (phaseIndex + 1) % BreathingPhase.cycle.count
        if phaseIndex == 0 { cycleCount += 1 }
        phase = BreathingPhase.cycle[phaseIndex]
        phaseProgress = 0
        phaseStart = Date()
    }
}
