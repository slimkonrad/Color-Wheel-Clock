import SwiftUI

struct StopwatchView: View {
    @StateObject private var vm = StopwatchViewModel()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hue: vm.currentHue, saturation: 0.40, brightness: 0.12),
                    Color(hue: vm.currentHue, saturation: 0.30, brightness: 0.06)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1), value: vm.currentHue)

            VStack(spacing: 0) {

                Text("stopwatch")
                    .font(.system(size: 11, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(3)
                    .textCase(.uppercase)
                    .padding(.top, 56)

                Spacer()

                ZStack {
                    Circle()
                        .fill(vm.currentColor.opacity(0.10))
                        .blur(radius: 50)
                        .scaleEffect(1.4)

                    HueRing(lineWidth: 22)

                    Circle()
                        .fill(Color.black.opacity(0.55))
                        .padding(22)

                    SweepArc(
                        progress: vm.elapsed.truncatingRemainder(dividingBy: 60) / 60,
                        color: vm.currentColor,
                        lineWidth: 22,
                        backgroundColor: .clear
                    )

                    TickMarks()

                    // ── Center — no pivot dot ────────────────────────
                    VStack(spacing: 4) {
                        Text(vm.displayString)
                            .font(.system(size: 38, weight: .thin, design: .monospaced))
                            .foregroundColor(.white)
                            .monospacedDigit()

                        Text(ColorNamer.name(for: vm.currentHue))
                            .font(.system(size: 13, weight: .light, design: .monospaced))
                            .foregroundColor(vm.currentColor)
                    }
                }
                .frame(width: 300, height: 300)

                Spacer()

                HStack(spacing: 40) {
                    CircleButton(
                        icon: vm.isRunning ? "flag.fill" : "arrow.counterclockwise",
                        color: .white.opacity(0.3)
                    ) {
                        if vm.isRunning {
                            vm.lap()
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } else {
                            vm.reset()
                        }
                    }

                    CircleButton(
                        icon: vm.isRunning ? "pause.fill" : "play.fill",
                        color: vm.currentColor,
                        size: 64
                    ) {
                        vm.toggle()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }

                    Circle().fill(Color.clear).frame(width: 48, height: 48)
                }
                .padding(.bottom, 20)

                if !vm.laps.isEmpty {
                    VStack(spacing: 0) {
                        HStack {
                            Text("lap"); Spacer()
                            Text("split"); Spacer()
                            Text("total")
                        }
                        .font(.system(size: 10, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(0.25))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)

                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(vm.laps) { lap in LapRow(lap: lap) }
                            }
                        }
                        .frame(maxHeight: 180)
                    }
                    .padding(.bottom, 100)
                } else {
                    Spacer().frame(height: 100)
                }
            }
        }
    }
}

struct LapRow: View {
    var lap: StopwatchLap
    var body: some View {
        HStack {
            Circle().fill(lap.color).frame(width: 8, height: 8)
            Text("#\(lap.number)").frame(width: 28, alignment: .leading)
            Spacer()
            Text(lap.splitString).foregroundColor(lap.color)
            Spacer()
            Text(lap.elapsedString).foregroundColor(.white.opacity(0.5))
        }
        .font(.system(size: 12, weight: .light, design: .monospaced))
        .foregroundColor(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .overlay(Rectangle().fill(.white.opacity(0.05)).frame(height: 0.5), alignment: .bottom)
    }
}

#Preview { StopwatchView() }
