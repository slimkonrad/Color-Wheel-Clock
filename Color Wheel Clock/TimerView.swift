import SwiftUI

struct TimerView: View {
    @StateObject private var vm = TimerViewModel()
    @State private var showPicker = false

    var body: some View {
        ZStack {
            // ── Gradient burn background ─────────────────────────────
            LinearGradient(
                colors: [vm.burnBackgroundTop, vm.burnBackgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1.5), value: vm.progress)

            VStack(spacing: 0) {
                Spacer()

                // ── Color sweep ring ─────────────────────────────────
                ZStack {
                    Circle()
                        .fill(vm.progressColor.opacity(0.10))
                        .blur(radius: 60)
                        .scaleEffect(1.3)

                    HueRing(lineWidth: 22, opacity: 0.18)

                    SweepArc(progress: vm.progress,
                             color: vm.progressColor,
                             lineWidth: 22)

                    Circle()
                        .fill(Color.black.opacity(0.60))
                        .padding(30)

                    VStack(spacing: 4) {
                        if vm.isFinished {
                            Text("done")
                                .font(.system(size: 16, weight: .light, design: .monospaced))
                                .foregroundColor(vm.progressColor)
                                .transition(.opacity)
                        }

                        // Preset name if active
                        if let preset = vm.selectedPreset {
                            Text(preset.name)
                                .font(.system(size: 11, weight: .light, design: .monospaced))
                                .foregroundColor(preset.color.opacity(0.7))
                        }

                        Text(vm.displayString)
                            .font(.system(size: 48, weight: .thin, design: .monospaced))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())

                        if !vm.isRunning && !vm.isFinished {
                            Button { showPicker.toggle() } label: {
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

                Spacer()

                // ── Color presets ────────────────────────────────────
                VStack(spacing: 10) {
                    Text("color sessions")
                        .font(.system(size: 10, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(0.3))
                        .tracking(2)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(TimerPreset.presets) { preset in
                                PresetButton(
                                    preset: preset,
                                    isSelected: vm.selectedPreset?.name == preset.name
                                ) {
                                    vm.applyPreset(preset)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                // ── Controls ─────────────────────────────────────────
                HStack(spacing: 40) {
                    CircleButton(icon: "arrow.counterclockwise", color: .white.opacity(0.3)) {
                        vm.reset()
                    }
                    CircleButton(
                        icon: vm.isRunning ? "pause.fill" : "play.fill",
                        color: vm.progressColor,
                        size: 64
                    ) { vm.toggle() }
                    CircleButton(icon: "plus", color: .white.opacity(0.3)) {
                        vm.inputMinutes += 1
                        vm.set()
                    }
                }
                .padding(.top, 24)

                // ── Progress label ────────────────────────────────────
                Text("\(Int(vm.progress * 100))% remaining")
                    .font(.system(size: 11, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.top, 12)
                    .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showPicker) {
            TimerPickerSheet(vm: vm, isPresented: $showPicker)
                .presentationDetents([.medium])
                .presentationBackground(.black)
        }
    }
}

// MARK: - Preset Button
struct PresetButton: View {
    var preset: TimerPreset
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Circle()
                    .fill(preset.color.opacity(isSelected ? 1.0 : 0.35))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle().stroke(preset.color.opacity(isSelected ? 0.8 : 0.2), lineWidth: 1.5)
                    )
                    .scaleEffect(isSelected ? 1.1 : 1.0)

                Text(preset.name)
                    .font(.system(size: 9, weight: .light, design: .monospaced))
                    .foregroundColor(isSelected ? preset.color : .white.opacity(0.35))

                Text("\(preset.minutes)m")
                    .font(.system(size: 8, weight: .thin, design: .monospaced))
                    .foregroundColor(.white.opacity(0.25))
            }
            .frame(width: 52)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
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
                vm.selectedPreset = nil
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
    TimerView()
}
