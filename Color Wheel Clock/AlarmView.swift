import SwiftUI
import AudioToolbox
import AVFoundation
import Combine
import UniformTypeIdentifiers

// MARK: - Alarm Sound
struct AlarmSound: Identifiable, Hashable {
    let id:        String
    let name:      String
    let systemID:  SystemSoundID?
    let isVibrate: Bool
    let isCustom:  Bool
    var customURL: URL?

    init(id: String, name: String, systemID: SystemSoundID?, isVibrate: Bool, isCustom: Bool = false, customURL: URL? = nil) {
        self.id        = id
        self.name      = name
        self.systemID  = systemID
        self.isVibrate = isVibrate
        self.isCustom  = isCustom
        self.customURL = customURL
    }

    static let options: [AlarmSound] = [
        AlarmSound(id: "chime",    name: "Chime",        systemID: 1013, isVibrate: false),
        AlarmSound(id: "bell",     name: "Bell",         systemID: 1005, isVibrate: false),
        AlarmSound(id: "tri",      name: "Tri-tone",     systemID: 1006, isVibrate: false),
        AlarmSound(id: "glass",    name: "Glass",        systemID: 1010, isVibrate: false),
        AlarmSound(id: "bloom",    name: "Bloom",        systemID: 1021, isVibrate: false),
        AlarmSound(id: "calypso",  name: "Calypso",      systemID: 1025, isVibrate: false),
        AlarmSound(id: "vibrate",  name: "Vibrate Only", systemID: nil,  isVibrate: true),
    ]

    func play() {
        if isCustom, let url = customURL {
            CustomAudioPlayer.shared.play(url: url)
        } else if isVibrate {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        } else if let sid = systemID {
            AudioServicesPlaySystemSound(sid)
        }
    }

    func stop() {
        CustomAudioPlayer.shared.stop()
    }
}

// MARK: - Custom Audio Player (singleton)
class CustomAudioPlayer: NSObject, ObservableObject {
    static let shared = CustomAudioPlayer()
    private var player: AVAudioPlayer?

    func play(url: URL) {
        stop()
        // Need security-scoped access for files picked from Files app
        let accessing = url.startAccessingSecurityScopedResource()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1 // loop until dismissed
            player?.play()
        } catch {
            print("Audio player error: \(error)")
        }
        if accessing { url.stopAccessingSecurityScopedResource() }
    }

    func stop() {
        player?.stop()
        player = nil
    }
}

// MARK: - Alarm Model
struct AlarmV2: Identifiable, Codable {
    var id          = UUID()
    var hour:       Int
    var minute:     Int
    var label:      String
    var hue:        Double
    var saturation: Double = 0.85
    var brightness: Double = 0.95
    var soundID:    String = "chime"
    var customSoundName: String? = nil
    var customSoundBookmark: Data? = nil  // security-scoped bookmark for persistence
    var enabled:    Bool   = true

    var color: Color { Color(hue: hue, saturation: saturation, brightness: brightness) }
    var colorName: String { ColorNamer.name(for: hue) }

    var timeString: String {
        let period = hour >= 12 ? "PM" : "AM"
        let h = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%d:%02d %@", h, minute, period)
    }

    var clockHue: Double {
        let h = Double(hour).truncatingRemainder(dividingBy: 12)
        return (h * 60 + Double(minute)) / 720.0
    }

    var resolvedCustomURL: URL? {
        guard let bookmark = customSoundBookmark else { return nil }
        var isStale = false
        return try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale)
    }

    var sound: AlarmSound {
        if soundID == "custom", let url = resolvedCustomURL {
            let name = customSoundName ?? "Custom Sound"
            return AlarmSound(id: "custom", name: name, systemID: nil, isVibrate: false, isCustom: true, customURL: url)
        }
        return AlarmSound.options.first { $0.id == soundID } ?? AlarmSound.options[0]
    }
}

// MARK: - Alarm ViewModel
class AlarmViewModelV2: ObservableObject {
    @Published var alarms:     [AlarmV2] = []
    @Published var firedAlarm: AlarmV2?  = nil

    private var cancellable: AnyCancellable?

    init() {
        cancellable = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.checkAlarms() }
    }

    func checkAlarms() {
        let cal = Calendar.current
        let now = Date()
        let h = cal.component(.hour,   from: now)
        let m = cal.component(.minute, from: now)
        for alarm in alarms where alarm.enabled {
            if alarm.hour == h && alarm.minute == m && firedAlarm == nil {
                firedAlarm = alarm
                alarm.sound.play()
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
        }
    }

    func add(_ alarm: AlarmV2)        { alarms.append(alarm) }
    func delete(at offsets: IndexSet) { alarms.remove(atOffsets: offsets) }
    func toggle(id: UUID) {
        if let i = alarms.firstIndex(where: { $0.id == id }) { alarms[i].enabled.toggle() }
    }
    func dismissFired() {
        firedAlarm?.sound.stop()
        firedAlarm = nil
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
}

// MARK: - Document Picker (audio files from Files app)
struct AudioFilePicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.audio, .mp3, .mpeg4Audio, .wav, .aiff]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}

// MARK: - AlarmView
struct AlarmView: View {
    @StateObject private var vm = AlarmViewModelV2()
    @State private var showAdd = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red:0.05,green:0.03,blue:0.12),
                         Color(red:0.02,green:0.02,blue:0.07)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("alarms")
                        .font(.system(size: 11, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(0.35))
                        .tracking(3)
                        .textCase(.uppercase)
                    Spacer()
                    Button { showAdd = true } label: {
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
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(vm.alarms) { alarm in
                                AlarmRowV2(alarm: alarm,
                                           onToggle: { vm.toggle(id: alarm.id) },
                                           onDelete: {
                                    if let i = vm.alarms.firstIndex(where: { $0.id == alarm.id }) {
                                        vm.delete(at: IndexSet([i]))
                                    }
                                })
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 120)
                    }
                }
            }

            if let fired = vm.firedAlarm {
                FiredAlarmOverlayV2(alarm: fired, onDismiss: vm.dismissFired)
            }
        }
        .sheet(isPresented: $showAdd) {
            AddAlarmSheetV2 { alarm in vm.add(alarm); showAdd = false }
                .presentationDetents([.large])
                .presentationBackground(.black)
        }
    }
}

// MARK: - Alarm Row
struct AlarmRowV2: View {
    var alarm:    AlarmV2
    var onToggle: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8)
                .fill(alarm.color.opacity(alarm.enabled ? 1 : 0.25))
                .frame(width: 36, height: 36)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.1), lineWidth: 0.5))

            VStack(alignment: .leading, spacing: 3) {
                Text(alarm.timeString)
                    .font(.system(size: 24, weight: .thin, design: .monospaced))
                    .foregroundColor(alarm.enabled ? .white : .white.opacity(0.3))

                HStack(spacing: 6) {
                    Text(alarm.label.isEmpty ? alarm.colorName : alarm.label)
                        .font(.system(size: 11, weight: .light, design: .monospaced))
                        .foregroundColor(alarm.enabled ? alarm.color.opacity(0.8) : .white.opacity(0.2))
                    Text("·").foregroundColor(.white.opacity(0.2))
                    Image(systemName: alarm.soundID == "custom" ? "music.note" : "bell")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.3))
                    Text(alarm.sound.name)
                        .font(.system(size: 10, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(alarm.enabled ? 0.3 : 0.15))
                        .lineLimit(1)
                }
            }

            Spacer()

            Toggle("", isOn: Binding(get: { alarm.enabled }, set: { _ in onToggle() }))
                .tint(alarm.color)
                .labelsHidden()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(alarm.enabled ? 0.06 : 0.03))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(alarm.color.opacity(alarm.enabled ? 0.25 : 0.08), lineWidth: 0.5))
        )
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) { Label("Delete", systemImage: "trash") }
        }
    }
}

// MARK: - Add Alarm Sheet
struct AddAlarmSheetV2: View {
    var onSave: (AlarmV2) -> Void

    @State private var hour           = 8
    @State private var minute         = 0
    @State private var label          = ""
    @State private var hue            = 0.62
    @State private var saturation     = 0.85
    @State private var brightness     = 0.95
    @State private var selectedSound  = AlarmSound.options[0]
    @State private var customURL:       URL?   = nil
    @State private var customName:      String = ""
    @State private var showFilePicker  = false
    @State private var page            = 0

    var clockHue: Double {
        let h = Double(hour).truncatingRemainder(dividingBy: 12)
        return (h * 60 + Double(minute)) / 720.0
    }
    var previewColor: Color { Color(hue: hue, saturation: saturation, brightness: brightness) }
    var isCustomSelected: Bool { selectedSound.id == "custom" }

    var body: some View {
        VStack(spacing: 0) {
            Text("new alarm")
                .font(.system(size: 13, weight: .light, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
                .tracking(2)
                .padding(.top, 24)
                .padding(.bottom, 16)

            // Step tabs
            HStack(spacing: 8) {
                ForEach(["time", "color", "sound"].indices, id: \.self) { idx in
                    let steps = ["time", "color", "sound"]
                    Text(steps[idx])
                        .font(.system(size: 9, weight: .light, design: .monospaced))
                        .foregroundColor(page == idx ? .white : .white.opacity(0.25))
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(page == idx ? .white.opacity(0.12) : .clear))
                        .onTapGesture { withAnimation { page = idx } }
                }
            }
            .padding(.bottom, 20)

            // ── Pages ─────────────────────────────────────────────────
            if page == 0 {
                // Time
                VStack(spacing: 12) {
                    let tc = Color(hue: clockHue, saturation: 0.85, brightness: 0.92)
                    VStack(spacing: 4) {
                        Circle().fill(tc).frame(width: 48, height: 48)
                            .shadow(color: tc.opacity(0.5), radius: 10)
                        Text(ColorNamer.name(for: clockHue))
                            .font(.system(size: 11, weight: .light, design: .monospaced))
                            .foregroundColor(tc)
                        Text("this time is \(ColorNamer.name(for: clockHue).lowercased())")
                            .font(.system(size: 9, weight: .light, design: .monospaced))
                            .foregroundColor(.white.opacity(0.2))
                    }

                    HStack(spacing: 0) {
                        Picker("Hour", selection: $hour) {
                            ForEach(0..<24) { h in
                                let p = h >= 12 ? "PM" : "AM"
                                let d = h % 12 == 0 ? 12 : h % 12
                                Text("\(d) \(p)").tag(h)
                                    .font(.system(size: 20, weight: .thin, design: .monospaced))
                            }
                        }
                        .pickerStyle(.wheel).frame(width: 140).clipped()
                        Text(":").font(.system(size: 24, weight: .thin)).foregroundColor(.white.opacity(0.4))
                        Picker("Minute", selection: $minute) {
                            ForEach(0..<60) { m in
                                Text(String(format: "%02d", m)).tag(m)
                                    .font(.system(size: 20, weight: .thin, design: .monospaced))
                            }
                        }
                        .pickerStyle(.wheel).frame(width: 100).clipped()
                    }
                    .colorScheme(.dark)

                    TextField("label (optional)", text: $label)
                        .font(.system(size: 13, weight: .light, design: .monospaced))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.07)))
                        .padding(.horizontal, 40)
                }

            } else if page == 1 {
                // Color
                ScrollView {
                    ChromaColorPicker(hue: $hue, saturation: $saturation, brightness: $brightness)
                        .padding(.bottom, 16)
                }

            } else {
                // Sound
                ScrollView {
                    VStack(spacing: 10) {

                        // ── System sounds ────────────────────────────
                        Text("system sounds")
                            .font(.system(size: 9, weight: .light, design: .monospaced))
                            .foregroundColor(.white.opacity(0.25))
                            .tracking(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)

                        ForEach(AlarmSound.options) { sound in
                            SoundRow(
                                icon: sound.isVibrate ? "iphone.radiowaves.left.and.right" : "music.note",
                                name: sound.name,
                                isSelected: selectedSound.id == sound.id && !isCustomSelected
                            ) {
                                selectedSound = sound
                                customURL = nil
                                sound.play()
                            }
                        }

                        // ── Custom sound ─────────────────────────────
                        Text("custom sound")
                            .font(.system(size: 9, weight: .light, design: .monospaced))
                            .foregroundColor(.white.opacity(0.25))
                            .tracking(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                        // Pick from Files
                        Button {
                            showFilePicker = true
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(previewColor.opacity(isCustomSelected ? 1 : 0.20))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "folder.badge.plus")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(customName.isEmpty ? "pick from files" : customName)
                                        .font(.system(size: 14, weight: .light, design: .monospaced))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Text(customName.isEmpty ? "mp3, m4a, wav, aiff" : "custom · tap to change")
                                        .font(.system(size: 9, weight: .light, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.3))
                                }

                                Spacer()

                                if isCustomSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12))
                                        .foregroundColor(previewColor)
                                }
                            }
                            .padding(.horizontal, 20).padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.white.opacity(isCustomSelected ? 0.10 : 0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(previewColor.opacity(isCustomSelected ? 0.4 : 0), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 20)
                }
            }

            Spacer()

            // Nav buttons
            HStack(spacing: 16) {
                if page > 0 {
                    Button { withAnimation { page -= 1 } } label: {
                        Text("back")
                            .font(.system(size: 14, weight: .light, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                            .frame(width: 90, height: 48)
                            .background(Capsule().fill(.white.opacity(0.07)))
                    }
                }

                if page < 2 {
                    Button { withAnimation { page += 1 } } label: {
                        Text("next")
                            .font(.system(size: 14, weight: .light, design: .monospaced))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Capsule().fill(previewColor))
                    }
                } else {
                    Button {
                        var alarm = AlarmV2(
                            hour: hour, minute: minute, label: label,
                            hue: hue, saturation: saturation, brightness: brightness,
                            soundID: isCustomSelected ? "custom" : selectedSound.id,
                            customSoundName: isCustomSelected ? customName : nil
                        )
                        // Save security-scoped bookmark for persistence
                        if let url = customURL {
                            alarm.customSoundBookmark = try? url.bookmarkData()
                        }
                        onSave(alarm)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        Text("set alarm")
                            .font(.system(size: 14, weight: .light, design: .monospaced))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Capsule().fill(previewColor))
                            .shadow(color: previewColor.opacity(0.4), radius: 10)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .foregroundColor(.white)
        .sheet(isPresented: $showFilePicker) {
            AudioFilePicker { url in
                _ = url.startAccessingSecurityScopedResource()
                customURL  = url
                customName = url.deletingPathExtension().lastPathComponent
                selectedSound = AlarmSound(id: "custom", name: customName,
                                           systemID: nil, isVibrate: false,
                                           isCustom: true, customURL: url)
                // Preview the sound
                CustomAudioPlayer.shared.play(url: url)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    CustomAudioPlayer.shared.stop()
                }
            }
        }
    }
}

// MARK: - Sound Row
struct SoundRow: View {
    var icon:       String
    var name:       String
    var isSelected: Bool
    var action:     () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(isSelected ? 0.25 : 0.08))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                Text(name)
                    .font(.system(size: 14, weight: .light, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(isSelected ? 0.10 : 0.04)))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }
}

// MARK: - Fired Alarm Overlay
struct FiredAlarmOverlayV2: View {
    var alarm:     AlarmV2
    var onDismiss: () -> Void
    @State private var pulse = false

    var body: some View {
        ZStack {
            alarm.color.opacity(0.20).ignoresSafeArea().blur(radius: 40)
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

                Text(alarm.label.isEmpty ? alarm.colorName : alarm.label)
                    .font(.system(size: 18, weight: .light, design: .monospaced))
                    .foregroundColor(alarm.color)

                Text(alarm.sound.name)
                    .font(.system(size: 11, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))

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

#Preview { AlarmView() }
