import SwiftUI

struct TimerView: View {
    @StateObject private var vm = TimerViewModel()
    @State private var showPicker = false

    var body: some View {
        VStack(spacing: 32) {

            // ── Color sweep ring ────────────────────────────────────
            ZStack {
                // Ambient glow
                Circle()
                    .fill(vm.progressColor.opacity(0.10))
                    .blur(radius: 60)
                    .scaleEffect(1.3)

                // Full spectrum background ring (dim)
                HueRing(lineWidth: 22, opacity: 0.18)

                // Sweeping progress arc
                SweepArc(progress: vm.progress,
                         color: vm.progressColor,
                         lineWidth: 22)

                // Dark inner fill
                Circle()
                    .fill(Color(white: 0.04))
                    .padding(30)

                // Center display
                VStack(spacing: 4) {
                    if vm.isFinished {
                        Text("done")
                            .font(.system(size: 16, weight: .light, design: .monospaced))
                            .foregroundColor(vm.progressColor)
                            .transition(.opacity)
                    }
                    Text(vm.displayString)
                        .font(.system(size: 48, weight: .thin, design: .monospaced))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())

                    if !vm.isRunning && !vm.isFinished {
                        Button {
                            showPicker.toggle()
                        } label: {
                            Text("set time")
                                .font(.system(size: 11, weight: .light, design: .monospaced))
                                .foregroundColor(.white.opacity(0.35))
                                .underline()
                        }
                    }
                }
            }
            .frame(width: 300, height: 300)
            .animation(.easeInOut(duration: 0.5), value: vm.progress)

            // ── Controls ─────────────────────────────────────────────
            HStack(spacing: 40) {
                // Reset
                CircleButton(
                    icon: "arrow.counterclockwise",
                    color: .white.opacity(0.3)
                ) { vm.reset() }

                // Play / Pause
                CircleButton(
                    icon: vm.isRunning ? "pause.fill" : "play.fill",
                    color: vm.progressColor,
                    size: 64
                ) { vm.toggle() }

                // Spacer symmetry
                CircleButton(
                    icon: "plus",
                    color: .white.opacity(0.3)
                ) {
                    vm.inputMinutes += 1
                    vm.set()
                }
            }

            // ── Progress label ──────────────────────────────────────
            Text(progressLabel)
                .font(.system(size: 11, weight: .light, design: .monospaced))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.vertical, 20)
        .sheet(isPresented: $showPicker) {
            TimerPickerSheet(vm: vm, isPresented: $showPicker)
                .presentationDetents([.medium])
                .presentationBackground(.black)
        }
    }

    var progressLabel: String {
        let pct = Int(vm.progress * 100)
        return "\(pct)% remaining"
    }
}

// MARK: - Timer Picker Sheet
struct TimerPickerSheet: View {
    @ObservedObject var vm: TimerViewModel
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 32) {
            Text("set timer")
                .font(.system(size: 13, weight: .light, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
                .padding(.top, 24)

            HStack(spacing: 0) {
                // Minutes
                Picker("Minutes", selection: $vm.inputMinutes) {
                    ForEach(0..<60) { m in
                        Text("\(m)").tag(m)
                            .font(.system(size: 32, weight: .thin, design: .monospaced))
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 120)
                .clipped()

                Text("m")
                    .font(.system(size: 18, weight: .thin, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))

                // Seconds
                Picker("Seconds", selection: $vm.inputSeconds) {
                    ForEach(0..<60) { s in
                        Text(String(format: "%02d", s)).tag(s)
                            .font(.system(size: 32, weight: .thin, design: .monospaced))
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 120)
                .clipped()

                Text("s")
                    .font(.system(size: 18, weight: .thin, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
            }
            .colorScheme(.dark)

            Button {
                vm.set()
                isPresented = false
            } label: {
                Text("start")
                    .font(.system(size: 15, weight: .light, design: .monospaced))
                    .foregroundColor(.black)
                    .frame(width: 160, height: 48)
                    .background(Color.white)
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .foregroundColor(.white)
    }
}

// MARK: - Reusable circle button
struct CircleButton: View {
    var icon: String
    var color: Color
    var size: CGFloat = 48
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: size, height: size)
                Image(systemName: icon)
                    .font(.system(size: size * 0.32, weight: .regular))
                    .foregroundColor(color)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        TimerView()
    }
}
