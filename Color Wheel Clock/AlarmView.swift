import SwiftUI

struct AlarmView: View {
    @StateObject private var vm = AlarmViewModel()
    @State private var showAddAlarm = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red:0.05,green:0.03,blue:0.12), Color(red:0.02,green:0.02,blue:0.07)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Header ───────────────────────────────────────────
                HStack {
                    Text("alarms")
                        .font(.system(size: 11, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(0.35))
                        .tracking(3)
                        .textCase(.uppercase)

                    Spacer()

                    Button {
                        showAddAlarm = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 56)
                .padding(.bottom, 24)

                if vm.alarms.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("no alarms")
                            .font(.system(size: 16, weight: .thin, design: .monospaced))
                            .foregroundColor(.white.opacity(0.25))
                        Text("tap + to add one")
                            .font(.system(size: 11, weight: .light, design: .monospaced))
                            .foregroundColor(.white.opacity(0.15))
                    }
                    Spacer()
                } else {
                    // ── Alarm list ───────────────────────────────────
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(vm.alarms) { alarm in
                                AlarmRow(alarm: alarm,
                                         onToggle: { vm.toggleAlarm(id: alarm.id) },
                                         onDelete: {
                                    if let i = vm.alarms.firstIndex(where: { $0.id == alarm.id }) {
                                        vm.deleteAlarm(at: IndexSet([i]))
                                    }
                                })
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 120)
                    }
                }
            }

            // ── Fired alarm overlay ──────────────────────────────────
            if let fired = vm.firedAlarm {
                FiredAlarmOverlay(alarm: fired) { vm.dismissFired() }
            }
        }
        .sheet(isPresented: $showAddAlarm) {
            AddAlarmSheet { alarm in
                vm.addAlarm(alarm)
                showAddAlarm = false
            }
            .presentationDetents([.large])
            .presentationBackground(.black)
        }
    }
}

// MARK: - Alarm Row
struct AlarmRow: View {
    var alarm: Alarm
    var onToggle: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Color swatch
            RoundedRectangle(cornerRadius: 8)
                .fill(alarm.color.opacity(alarm.enabled ? 1.0 : 0.25))
                .frame(width: 36, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.1), lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(alarm.timeString)
                    .font(.system(size: 24, weight: .thin, design: .monospaced))
                    .foregroundColor(alarm.enabled ? .white : .white.opacity(0.3))

                HStack(spacing: 6) {
                    Text(alarm.label.isEmpty ? ColorNamer.name(for: alarm.hue) : alarm.label)
                        .font(.system(size: 11, weight: .light, design: .monospaced))
                        .foregroundColor(alarm.enabled ? alarm.color.opacity(0.8) : .white.opacity(0.2))
                }
            }

            Spacer()

            // Toggle
            Toggle("", isOn: Binding(get: { alarm.enabled }, set: { _ in onToggle() }))
                .tint(alarm.color)
                .labelsHidden()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(alarm.enabled ? 0.06 : 0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(alarm.color.opacity(alarm.enabled ? 0.25 : 0.08), lineWidth: 0.5)
                )
        )
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Add Alarm Sheet
struct AddAlarmSheet: View {
    var onSave: (Alarm) -> Void

    @State private var selectedHour   = 8
    @State private var selectedMinute = 0
    @State private var label          = ""
    @State private var selectedHue    = 0.62

    // The color wheel hue for the chosen time
    var clockHue: Double {
        let h = Double(selectedHour).truncatingRemainder(dividingBy: 12)
        return (h * 60 + Double(selectedMinute)) / 720.0
    }

    var timeColor: Color { Color(hue: clockHue, saturation: 0.85, brightness: 0.92) }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("new alarm")
                .font(.system(size: 13, weight: .light, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
                .tracking(2)
                .padding(.top, 24)
                .padding(.bottom, 20)

            // Color preview of the chosen time
            VStack(spacing: 6) {
                Circle()
                    .fill(timeColor)
                    .frame(width: 56, height: 56)
                    .shadow(color: timeColor.opacity(0.5), radius: 12)

                Text(ColorNamer.name(for: clockHue))
                    .font(.system(size: 13, weight: .light, design: .monospaced))
                    .foregroundColor(timeColor)

                Text("this time is \(ColorNamer.name(for: clockHue).lowercased())")
                    .font(.system(size: 10, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.25))
            }
            .padding(.bottom, 20)

            // Time pickers
            HStack(spacing: 0) {
                Picker("Hour", selection: $selectedHour) {
                    ForEach(0..<24) { h in
                        let period = h >= 12 ? "PM" : "AM"
                        let display = h % 12 == 0 ? 12 : h % 12
                        Text("\(display) \(period)").tag(h)
                            .font(.system(size: 22, weight: .thin, design: .monospaced))
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 140)
                .clipped()

                Text(":")
                    .font(.system(size: 24, weight: .thin, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))

                Picker("Minute", selection: $selectedMinute) {
                    ForEach(0..<60) { m in
                        Text(String(format: "%02d", m)).tag(m)
                            .font(.system(size: 22, weight: .thin, design: .monospaced))
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 100)
                .clipped()
            }
            .colorScheme(.dark)

            // Label field
            TextField("label (optional)", text: $label)
                .font(.system(size: 14, weight: .light, design: .monospaced))
                .foregroundColor(.white)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.07)))
                .padding(.horizontal, 24)
                .padding(.top, 16)

            Spacer()

            // Save
            Button {
                onSave(Alarm(
                    hour: selectedHour,
                    minute: selectedMinute,
                    label: label,
                    hue: clockHue
                ))
            } label: {
                Text("set alarm")
                    .font(.system(size: 15, weight: .light, design: .monospaced))
                    .foregroundColor(.black)
                    .frame(width: 200, height: 50)
                    .background(timeColor)
                    .clipShape(Capsule())
                    .shadow(color: timeColor.opacity(0.4), radius: 10)
            }
            .padding(.bottom, 40)
        }
        .foregroundColor(.white)
    }
}

// MARK: - Fired Alarm Overlay
struct FiredAlarmOverlay: View {
    var alarm: Alarm
    var onDismiss: () -> Void
    @State private var pulse = false

    var body: some View {
        ZStack {
            alarm.color.opacity(0.25).ignoresSafeArea()
                .blur(radius: 40)

            VStack(spacing: 24) {
                Circle()
                    .fill(alarm.color.opacity(0.85))
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulse ? 1.12 : 0.92)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
                    .onAppear { pulse = true }

                Text(alarm.timeString)
                    .font(.system(size: 48, weight: .thin, design: .monospaced))
                    .foregroundColor(.white)

                Text(alarm.label.isEmpty ? ColorNamer.name(for: alarm.hue) : alarm.label)
                    .font(.system(size: 18, weight: .light, design: .monospaced))
                    .foregroundColor(alarm.color)

                Button(action: onDismiss) {
                    Text("dismiss")
                        .font(.system(size: 16, weight: .light, design: .monospaced))
                        .foregroundColor(.black)
                        .frame(width: 160, height: 50)
                        .background(.white)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

#Preview {
    AlarmView()
}
