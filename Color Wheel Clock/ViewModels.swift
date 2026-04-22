import SwiftUI
import Combine

// MARK: - Time → Color Mapping
// Hours (0–12)   → Hue (0°–360°)      full spectrum over 12 hrs
// Minutes (0–60) → Saturation (40%–100%)
// Seconds (0–60) → Brightness pulse (subtle ±5%)

struct TimeColor {
    let hue: Double
    let saturation: Double
    let brightness: Double

    var color: Color {
        Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    var secondaryColor: Color {
        // Complementary hue, dimmer — used for the ring background
        Color(hue: (hue + 0.5).truncatingRemainder(dividingBy: 1.0),
              saturation: saturation * 0.3,
              brightness: 0.15)
    }

    static func from(date: Date) -> TimeColor {
        let cal = Calendar.current
        let hour   = Double(cal.component(.hour,   from: date)) .truncatingRemainder(dividingBy: 12)
        let minute = Double(cal.component(.minute, from: date))
        let second = Double(cal.component(.second, from: date))

        let hue        = (hour * 60 + minute) / 720.0           // 12h → 0…1
        let saturation = 0.55 + (minute / 60.0) * 0.45          // 55%…100%
        let pulse      = sin(second / 60.0 * .pi)               // 0→1→0 over the minute
        let brightness = 0.80 + pulse * 0.10                    // 80%…90%

        return TimeColor(hue: hue, saturation: saturation, brightness: brightness)
    }
}

// MARK: - Clock ViewModel
class ClockViewModel: ObservableObject {
    @Published var currentDate = Date()
    @Published var timeColor   = TimeColor.from(date: Date())

    private var timer: AnyCancellable?

    init() { start() }

    func start() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.currentDate = date
                self?.timeColor   = TimeColor.from(date: date)
            }
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
    @Published var totalSeconds: Int    = 60
    @Published var remainingSeconds: Int = 60
    @Published var isRunning: Bool      = false
    @Published var isFinished: Bool     = false

    // Input state
    @Published var inputMinutes: Int = 1
    @Published var inputSeconds: Int = 0

    private var timer: AnyCancellable?

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(remainingSeconds) / Double(totalSeconds)
    }

    var progressColor: Color {
        // Full → warm red, empty → cool blue/grey
        let hue = 0.0 + progress * 0.35   // red(0) → green(0.35) as time remains
        return Color(hue: hue, saturation: 0.8, brightness: 0.9)
    }

    var displayString: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    func set() {
        totalSeconds     = inputMinutes * 60 + inputSeconds
        remainingSeconds = totalSeconds
        isFinished       = false
    }

    func toggle() {
        if isRunning { pause() } else { play() }
    }

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
