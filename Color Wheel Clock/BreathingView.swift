import SwiftUI

struct BreathingView: View {
    @StateObject private var vm = BreathingViewModel()

    var body: some View {
        ZStack {
            // Background shifts softly with the breathing hue
            LinearGradient(
                colors: [
                    Color(hue: vm.currentHue, saturation: 0.35, brightness: 0.12),
                    Color(hue: vm.currentHue, saturation: 0.25, brightness: 0.06)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 3), value: vm.currentHue)

            VStack(spacing: 0) {

                // ── Header ───────────────────────────────────────────
                VStack(spacing: 4) {
                    Text("breathe")
                        .font(.system(size: 11, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(0.35))
                        .tracking(3)
                        .textCase(.uppercase)

                    if vm.cycleCount > 0 {
                        Text("\(vm.cycleCount) \(vm.cycleCount == 1 ? "cycle" : "cycles")")
                            .font(.system(size: 11, weight: .thin, design: .monospaced))
                            .foregroundColor(vm.color.opacity(0.6))
                    }
                }
                .padding(.top, 56)

                Spacer()

                // ── Breathing orb ─────────────────────────────────────
                ZStack {
                    // Outer soft glow rings
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(vm.color.opacity(0.04 - Double(i) * 0.01))
                            .scaleEffect(vm.scale + CGFloat(i) * 0.18)
                            .animation(
                                .easeInOut(duration: vm.phase.duration),
                                value: vm.scale
                            )
                    }

                    // Main orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [vm.color, vm.ringColor.opacity(0.6)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(vm.scale)
                        .animation(
                            .easeInOut(duration: vm.phase.duration),
                            value: vm.scale
                        )
                        .shadow(color: vm.color.opacity(0.4), radius: 30)

                    // Phase progress ring
                    Circle()
                        .trim(from: 0, to: CGFloat(vm.phaseProgress))
                        .stroke(vm.color.opacity(0.6),
                                style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.05), value: vm.phaseProgress)
                }
                .frame(width: 260, height: 260)

                Spacer()

                // ── Phase instruction ────────────────────────────────
                VStack(spacing: 8) {
                    Text(vm.isRunning ? vm.phase.instruction : "tap to begin")
                        .font(.system(size: 22, weight: .thin, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                        .animation(.easeInOut(duration: 0.4), value: vm.phase.instruction)
                        .contentTransition(.opacity)

                    if vm.isRunning {
                        Text(phaseTimingLabel)
                            .font(.system(size: 11, weight: .light, design: .monospaced))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .frame(height: 60)

                Spacer()

                // ── Pattern guide ────────────────────────────────────
                HStack(spacing: 20) {
                    PhaseLabel(name: "in",   seconds: 4, color: vm.color, active: vm.phase == .inhale && vm.isRunning)
                    PhaseLabel(name: "hold", seconds: 4, color: vm.color, active: vm.phase == .hold   && vm.isRunning)
                    PhaseLabel(name: "out",  seconds: 6, color: vm.color, active: vm.phase == .exhale && vm.isRunning)
                    PhaseLabel(name: "rest", seconds: 2, color: vm.color, active: vm.phase == .rest   && vm.isRunning)
                }
                .padding(.bottom, 32)

                // ── Controls ─────────────────────────────────────────
                HStack(spacing: 40) {
                    CircleButton(icon: "arrow.counterclockwise", color: .white.opacity(0.3)) {
                        vm.stop()
                    }
                    CircleButton(
                        icon: vm.isRunning ? "pause.fill" : "play.fill",
                        color: vm.color,
                        size: 64
                    ) { vm.toggle() }

                    Circle().fill(Color.clear).frame(width: 48, height: 48)
                }
                .padding(.bottom, 100)
            }
        }
    }

    var phaseTimingLabel: String {
        let remaining = vm.phase.duration * (1 - vm.phaseProgress)
        return String(format: "%.0fs", remaining)
    }
}

struct PhaseLabel: View {
    var name: String
    var seconds: Int
    var color: Color
    var active: Bool

    var body: some View {
        VStack(spacing: 3) {
            Text(name)
                .font(.system(size: 10, weight: active ? .medium : .light, design: .monospaced))
                .foregroundColor(active ? color : .white.opacity(0.25))
            Text("\(seconds)s")
                .font(.system(size: 9, weight: .thin, design: .monospaced))
                .foregroundColor(active ? color.opacity(0.7) : .white.opacity(0.15))
        }
        .animation(.easeInOut(duration: 0.3), value: active)
    }
}

#Preview {
    BreathingView()
}
