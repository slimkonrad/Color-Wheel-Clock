import SwiftUI

struct ClockView: View {
    @StateObject private var vm = ClockViewModel()
    @State private var showSnapshots = false
    @State private var didSave = false

    var body: some View {
        ZStack {
            // ── Time-of-day background ───────────────────────────────
            LinearGradient(
                colors: [vm.theme.backgroundTop, vm.theme.backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 4), value: vm.theme.label)

            VStack(spacing: 0) {

                // ── Time of day label ────────────────────────────────
                Text(vm.theme.label)
                    .font(.system(size: 11, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(3)
                    .textCase(.uppercase)
                    .padding(.top, 56)
                    .animation(.easeInOut(duration: 2), value: vm.theme.label)

                Spacer()

                // ── Clock face ───────────────────────────────────────
                ZStack {
                    // Ambient glow
                    Circle()
                        .fill(vm.timeColor.color.opacity(0.10))
                        .blur(radius: 50)
                        .scaleEffect(1.4)

                    // Full spectrum ring
                    HueRing(lineWidth: 22)

                    // Dark overlay
                    Circle()
                        .fill(Color.black.opacity(0.50))
                        .padding(22)

                    // Color trail arc
                    ColorTrailView(trail: vm.colorTrail)
                        .padding(22)

                    // Tick marks
                    TickMarks()

                    // Radial center glow
                    Circle()
                        .fill(RadialGradient(
                            colors: [vm.timeColor.color.opacity(0.20), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 110
                        ))
                        .padding(44)

                    // Hour hand
                    ClockHand(angle: vm.hourAngle, length: 0.42, width: 5,   color: .white)
                    // Minute hand
                    ClockHand(angle: vm.minuteAngle, length: 0.60, width: 3, color: .white.opacity(0.85))
                    // Second hand — colored
                    ClockHand(angle: vm.secondAngle, length: 0.68, width: 1.5,
                              color: vm.timeColor.color, hasDot: true)

                    // Center pivot
                    Circle().fill(vm.timeColor.color).frame(width: 10, height: 10)
                }
                .frame(width: 300, height: 300)
                .animation(.easeInOut(duration: 0.4), value: vm.timeColor.hue)

                Spacer()

                // ── Color name + digital readout ─────────────────────
                VStack(spacing: 8) {
                    // Color name — the big unique label
                    Text(vm.timeColor.name)
                        .font(.system(size: 22, weight: .thin, design: .monospaced))
                        .foregroundColor(vm.timeColor.color)
                        .animation(.easeInOut(duration: 0.6), value: vm.timeColor.name)
                        .contentTransition(.opacity)

                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text(vm.timeString)
                            .font(.system(size: 32, weight: .thin, design: .monospaced))
                            .foregroundColor(.white)
                        Text(vm.periodString)
                            .font(.system(size: 13, weight: .light, design: .monospaced))
                            .foregroundColor(vm.timeColor.color)
                    }
                }
                .padding(.bottom, 28)

                // ── Palette snapshot button + strip ──────────────────
                VStack(spacing: 14) {
                    Button {
                        vm.saveSnapshot()
                        withAnimation { didSave = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            withAnimation { didSave = false }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: didSave ? "checkmark" : "square.and.arrow.down")
                                .font(.system(size: 12))
                            Text(didSave ? "saved" : "save color")
                                .font(.system(size: 12, weight: .light, design: .monospaced))
                        }
                        .foregroundColor(didSave ? vm.timeColor.color : .white.opacity(0.4))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(.white.opacity(0.07)))
                    }
                    .buttonStyle(.plain)

                    // Saved swatches strip
                    if !vm.snapshots.isEmpty {
                        Button { showSnapshots.toggle() } label: {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(vm.snapshots.prefix(12)) { snap in
                                        Circle()
                                            .fill(snap.color)
                                            .frame(width: 20, height: 20)
                                            .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 0.5))
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showSnapshots) {
            SnapshotGalleryView(snapshots: vm.snapshots)
                .presentationDetents([.medium, .large])
                .presentationBackground(.black)
        }
    }
}

// MARK: - Color Trail Arc
struct ColorTrailView: View {
    var trail: [TimeColor]

    var body: some View {
        GeometryReader { geo in
            let size   = min(geo.size.width, geo.size.height)
            let radius = size / 2 - 2
            let count  = trail.count

            Canvas { ctx, canvasSize in
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                guard count > 1 else { return }

                for i in 0..<count {
                    let progress = Double(i) / Double(count)
                    let opacity  = progress * 0.55        // fades toward oldest
                    let width    = CGFloat(1.5 + progress * 3.5)

                    // Map trail index to angle on the ring
                    // Most recent = current second angle, going backwards
                    let secondFraction = Double(i) / 60.0
                    let startAngle = Double(count - 1 - i) * (1.0 / 60.0) * 2 * .pi - .pi / 2
                    let endAngle   = startAngle + (1.0 / 60.0) * 2 * .pi

                    var path = Path()
                    path.addArc(center: center,
                                radius: radius * 0.72,
                                startAngle: .radians(startAngle),
                                endAngle:   .radians(endAngle),
                                clockwise: false)

                    ctx.stroke(path,
                               with: .color(trail[i].color.opacity(opacity)),
                               style: StrokeStyle(lineWidth: width, lineCap: .round))
                }
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Snapshot Gallery
struct SnapshotGalleryView: View {
    var snapshots: [PaletteSnapshot]

    var body: some View {
        VStack(spacing: 0) {
            Text("color moments")
                .font(.system(size: 13, weight: .light, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
                .tracking(2)
                .padding(.top, 24)
                .padding(.bottom, 20)

            if snapshots.isEmpty {
                Spacer()
                Text("no snapshots yet")
                    .font(.system(size: 14, weight: .thin, design: .monospaced))
                    .foregroundColor(.white.opacity(0.25))
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                              spacing: 12) {
                        ForEach(snapshots) { snap in
                            VStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(snap.color)
                                    .frame(height: 80)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                                    )
                                Text(snap.name)
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.7))
                                Text(snap.timeString)
                                    .font(.system(size: 9, weight: .light, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.35))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .foregroundColor(.white)
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
    ClockView()
}
