import SwiftUI
import AudioToolbox

struct TimerView: View {
    @StateObject private var vm = TimerViewModel()
    @State private var showPicker    = false
    @State private var showAddPreset = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [vm.burnBackgroundTop, vm.burnBackgroundBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1.5), value: vm.progress)

            VStack(spacing: 0) {
                Text("timer")
                    .font(.system(size: 11, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(3)
                    .textCase(.uppercase)
                    .padding(.top, 56)

                Spacer()

                // ── Ring ─────────────────────────────────────────────
                ZStack {
                    Circle()
                        .fill(vm.progressColor.opacity(0.10))
                        .blur(radius: 60)
                        .scaleEffect(1.3)

                    HueRing(lineWidth: 22, opacity: 0.18)
                    SweepArc(progress: vm.progress, color: vm.progressColor, lineWidth: 22)

                    Circle()
                        .fill(Color.black.opacity(0.60))
                        .padding(30)

                    VStack(spacing: 6) {
                        if vm.isFinished {
                            Text("done")
                                .font(.system(size: 14, weight: .light, design: .monospaced))
                                .foregroundColor(vm.progressColor)
                                .transition(.opacity)
                        }
                        if let preset = vm.selectedPreset {
                            Text(preset.name)
                                .font(.system(size: 11, weight: .light, design: .monospaced))
                                .foregroundColor(preset.color.opacity(0.7))
                        }
                        Text(vm.displayString)
                            .font(.system(size: 44, weight: .thin, design: .monospaced))
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
                .frame(width: 290, height: 290)
                .animation(.easeInOut(duration: 0.5), value: vm.progress)
                .onChange(of: vm.isFinished) { _, finished in
                    if finished {
                        AudioServicesPlaySystemSound(1013)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    } 
                }

                Spacer()

                // ── Sessions header ───────────────────────────────────
                HStack {
                    Text("color sessions")
                        .font(.system(size: 10, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(0.3))
                        .tracking(2)
                    Spacer()
                    Button { showAddPreset = true } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus").font(.system(size: 10))
                            Text("new").font(.system(size: 10, weight: .light, design: .monospaced))
                        }
                        .foregroundColor(.white.opacity(0.35))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 10)

                // ── Preset row ────────────────────────────────────────
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(vm.presets) { preset in
                            PresetButton(
                                preset: preset,
                                isSelected: vm.selectedPreset?.id == preset.id
                            ) { vm.applyPreset(preset) }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                // ── Controls ─────────────────────────────────────────
                HStack(spacing: 40) {
                    CircleButton(icon: "arrow.counterclockwise", color: .white.opacity(0.3)) {
                        vm.reset()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    CircleButton(
                        icon: vm.isRunning ? "pause.fill" : "play.fill",
                        color: vm.progressColor, size: 64
                    ) {
                        vm.toggle()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                    CircleButton(icon: "plus", color: .white.opacity(0.3)) {
                        vm.inputMinutes += 1; vm.set()
                    }
                }
                .padding(.top, 20)

                Text("\(Int(vm.progress * 100))% remaining")
                    .font(.system(size: 11, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.25))
                    .padding(.top, 10)
                    .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showPicker) {
            TimerPickerSheet(vm: vm, isPresented: $showPicker)
                .presentationDetents([.medium])
                .presentationBackground(.black)
        }
        .sheet(isPresented: $showAddPreset) {
            AddPresetSheet { preset in
                vm.addPreset(preset)
                showAddPreset = false
            }
            .presentationDetents([.large])
            .presentationBackground(.black)
        }
    }
}

// MARK: - Preset Button
struct PresetButton: View {
    var preset:     TimerPreset
    var isSelected: Bool
    var action:     () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Circle()
                    .fill(preset.color.opacity(isSelected ? 1.0 : 0.30))
                    .frame(width: 34, height: 34)
                    .overlay(Circle().stroke(preset.color.opacity(isSelected ? 0.8 : 0.2), lineWidth: 1.5))
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .shadow(color: isSelected ? preset.color.opacity(0.4) : .clear, radius: 6)

                Text(preset.name)
                    .font(.system(size: 9, weight: .light, design: .monospaced))
                    .foregroundColor(isSelected ? preset.color : .white.opacity(0.35))
                    .lineLimit(1)

                Text(preset.seconds > 0
                     ? "\(preset.minutes)m\(preset.seconds)s"
                     : "\(preset.minutes)m")
                    .font(.system(size: 8, weight: .thin, design: .monospaced))
                    .foregroundColor(.white.opacity(0.22))
            }
            .frame(width: 56)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Add Preset Sheet
struct AddPresetSheet: View {
    var onSave: (TimerPreset) -> Void

    @State private var name       = ""
    @State private var minutes    = 25
    @State private var secs       = 0
    @State private var hue        = 0.62
    @State private var saturation = 0.85
    @State private var brightness = 0.95

    var previewColor: Color { Color(hue: hue, saturation: saturation, brightness: brightness) }

    var body: some View {
        VStack(spacing: 0) {
            Text("new session")
                .font(.system(size: 13, weight: .light, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
                .tracking(2)
                .padding(.top, 24)
                .padding(.bottom, 20)

            // Name
            TextField("session name", text: $name)
                .font(.system(size: 14, weight: .light, design: .monospaced))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.07)))
                .padding(.horizontal, 40)
                .padding(.bottom, 16)

            // Duration
            HStack(spacing: 0) {
                Picker("Minutes", selection: $minutes) {
                    ForEach(0..<120) { m in
                        Text("\(m)m").tag(m)
                            .font(.system(size: 22, weight: .thin, design: .monospaced))
                    }
                }
                .pickerStyle(.wheel).frame(width: 110).clipped()

                Picker("Seconds", selection: $secs) {
                    ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { s in
                        Text(String(format: "%02ds", s)).tag(s)
                            .font(.system(size: 22, weight: .thin, design: .monospaced))
                    }
                }
                .pickerStyle(.wheel).frame(width: 110).clipped()
            }
            .colorScheme(.dark)
            .padding(.bottom, 16)

            // Color picker
            ScrollView {
                ChromaColorPicker(hue: $hue, saturation: $saturation, brightness: $brightness)
                    .padding(.bottom, 16)
            }

            Spacer()

            Button {
                guard !name.isEmpty else { return }
                onSave(TimerPreset(name: name, minutes: minutes, seconds: secs, hue: hue))
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                Text("save session")
                    .font(.system(size: 15, weight: .light, design: .monospaced))
                    .foregroundColor(.black)
                    .frame(width: 200, height: 50)
                    .background(name.isEmpty ? Color.gray.opacity(0.4) : previewColor)
                    .clipShape(Capsule())
                    .shadow(color: previewColor.opacity(name.isEmpty ? 0 : 0.4), radius: 10)
            }
            .disabled(name.isEmpty)
            .padding(.bottom, 40)
        }
        .foregroundColor(.white)
    }
}

// MARK: - Timer Picker Sheet
struct TimerPickerSheet: View {
    @ObservedObject var vm: TimerViewModel
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 28) {
            Text("set timer")
                .font(.system(size: 13, weight: .light, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
                .padding(.top, 24)

            HStack(spacing: 0) {
                Picker("Minutes", selection: $vm.inputMinutes) {
                    ForEach(0..<120) { m in
                        Text("\(m)").tag(m)
                            .font(.system(size: 32, weight: .thin, design: .monospaced))
                    }
                }
                .pickerStyle(.wheel).frame(width: 120).clipped()

                Text("m")
                    .font(.system(size: 18, weight: .thin)).foregroundColor(.white.opacity(0.4))

                Picker("Seconds", selection: $vm.inputSeconds) {
                    ForEach(0..<60) { s in
                        Text(String(format: "%02d", s)).tag(s)
                            .font(.system(size: 32, weight: .thin, design: .monospaced))
                    }
                }
                .pickerStyle(.wheel).frame(width: 120).clipped()

                Text("s")
                    .font(.system(size: 18, weight: .thin)).foregroundColor(.white.opacity(0.4))
            }
            .colorScheme(.dark)

            Button {
                vm.selectedPreset = nil; vm.set(); isPresented = false
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
    var icon:   String
    var color:  Color
    var size:   CGFloat = 48
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: size, height: size)
                Image(systemName: icon)
                    .font(.system(size: size * 0.32, weight: .regular))
                    .foregroundColor(color)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview { TimerView() }
