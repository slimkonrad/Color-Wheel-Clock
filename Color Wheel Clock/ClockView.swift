import SwiftUI

struct ClockView: View {
    @StateObject private var vm = ClockViewModel()

    var body: some View {
        VStack(spacing: 32) {

            // ── Color wheel clock face ──────────────────────────────
            ZStack {
                // Background glow matching current hue
                Circle()
                    .fill(vm.timeColor.color.opacity(0.08))
                    .blur(radius: 60)
                    .scaleEffect(1.3)

                // Spectrum ring
                HueRing(lineWidth: 22)

                // Dim overlay so hands read clearly
                Circle()
                    .fill(Color.black.opacity(0.55))
                    .padding(22)

                // Tick marks
                TickMarks()

                // Colored center fill — reflects current time's hue
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [vm.timeColor.color.opacity(0.18), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .padding(44)

                // Hour hand
                ClockHand(angle: vm.hourAngle,
                          length: 0.42,
                          width: 5,
                          color: .white)

                // Minute hand
                ClockHand(angle: vm.minuteAngle,
                          length: 0.60,
                          width: 3,
                          color: .white.opacity(0.85))

                // Second hand — colored by current hue
                ClockHand(angle: vm.secondAngle,
                          length: 0.68,
                          width: 1.5,
                          color: vm.timeColor.color,
                          hasDot: true)

                // Center pivot
                Circle()
                    .fill(vm.timeColor.color)
                    .frame(width: 10, height: 10)
            }
            .frame(width: 300, height: 300)
            .animation(.easeInOut(duration: 0.4), value: vm.timeColor.hue)

            // ── Digital readout ─────────────────────────────────────
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(vm.timeString)
                    .font(.system(size: 38, weight: .thin, design: .monospaced))
                    .foregroundColor(.white)

                Text(vm.periodString)
                    .font(.system(size: 14, weight: .light, design: .monospaced))
                    .foregroundColor(vm.timeColor.color)
            }

            // ── Hue legend ──────────────────────────────────────────
            HStack(spacing: 16) {
                LegendDot(color: vm.timeColor.color, label: "now")
            }
            .font(.system(size: 11, weight: .light, design: .monospaced))
            .foregroundColor(.white.opacity(0.4))
        }
        .padding(.vertical, 20)
    }
}

struct LegendDot: View {
    var color: Color
    var label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ClockView()
    }
}
