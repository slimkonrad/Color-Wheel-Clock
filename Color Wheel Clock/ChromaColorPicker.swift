import SwiftUI

// MARK: - Shared Color Picker
struct ChromaColorPicker: View {
    @Binding var hue:        Double
    @Binding var saturation: Double
    @Binding var brightness: Double

    @State private var mode: PickerMode = .swatches

    enum PickerMode: String, CaseIterable {
        case swatches = "swatches"
        case sliders  = "sliders"
    }

    var color:     Color  { Color(hue: hue, saturation: saturation, brightness: brightness) }
    var colorName: String { ColorNamer.name(for: hue) }

    var body: some View {
        VStack(spacing: 12) {

            // ── Preview swatch ───────────────────────────────────────
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color)
                    .frame(width: 44, height: 44)
                    .shadow(color: color.opacity(0.5), radius: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(colorName)
                        .font(.system(size: 15, weight: .light, design: .monospaced))
                        .foregroundColor(color)
                    Text("H:\(Int(hue*360))°  S:\(Int(saturation*100))%  B:\(Int(brightness*100))%")
                        .font(.system(size: 9, weight: .thin, design: .monospaced))
                        .foregroundColor(.white.opacity(0.25))
                }

                Spacer()

                // Mode toggle
                HStack(spacing: 2) {
                    ForEach(PickerMode.allCases, id: \.self) { m in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { mode = m }
                        } label: {
                            Text(m.rawValue)
                                .font(.system(size: 9, weight: .light, design: .monospaced))
                                .foregroundColor(mode == m ? .black : .white.opacity(0.4))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(mode == m ? Color.white : Color.clear))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(Capsule().fill(.white.opacity(0.08)))
            }
            .padding(.horizontal, 20)

            // ── Content ──────────────────────────────────────────────
            if mode == .swatches {
                SwatchGrid(selectedHue: $hue)
            } else {
                HSBSliders(hue: $hue, saturation: $saturation, brightness: $brightness)
            }
        }
    }
}

// MARK: - Swatch Grid (40 named colors)
struct SwatchGrid: View {
    @Binding var selectedHue: Double

    let colors: [(name: String, hue: Double)] = [
        ("Crimson",     0.000), ("Scarlet",     0.022), ("Red Orange",  0.044),
        ("Vermillion",  0.061), ("Tangerine",   0.083), ("Amber",       0.111),
        ("Golden",      0.139), ("Yellow",      0.167), ("Citrus",      0.194),
        ("Chartreuse",  0.222), ("Lime",        0.250), ("Grass",       0.278),
        ("Emerald",     0.306), ("Forest",      0.333), ("Jade",        0.361),
        ("Mint",        0.444), ("Aquamarine",  0.472), ("Teal",        0.490),
        ("Cyan",        0.500), ("Sky",         0.528), ("Cerulean",    0.556),
        ("Cornflower",  0.583), ("Sky Blue",    0.597), ("Cobalt",      0.625),
        ("Indigo",      0.653), ("Sapphire",    0.681), ("Navy",        0.694),
        ("Periwinkle",  0.708), ("Violet",      0.736), ("Amethyst",    0.764),
        ("Lavender",    0.778), ("Purple",      0.806), ("Plum",        0.819),
        ("Magenta",     0.833), ("Hot Pink",    0.847), ("Fuchsia",     0.875),
        ("Rose",        0.903), ("Blush",       0.931), ("Ruby",        0.958),
        ("Punch",       0.972),
    ]

    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 8)

    var body: some View {
        VStack(spacing: 8) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(colors, id: \.name) { entry in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { selectedHue = entry.hue }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hue: entry.hue, saturation: 0.85, brightness: 0.95))
                                .frame(height: 32)
                            if abs(selectedHue - entry.hue) < 0.015 {
                                Circle().stroke(Color.white, lineWidth: 2.5).frame(height: 32)
                                Circle().fill(Color.white.opacity(0.20)).frame(height: 32)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)

            // Selected name
            if let match = colors.min(by: { abs($0.hue - selectedHue) < abs($1.hue - selectedHue) }) {
                Text(match.name)
                    .font(.system(size: 10, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
    }
}

// MARK: - HSB Sliders (no UIScreen.main — uses GeometryReader)
struct HSBSliders: View {
    @Binding var hue:        Double
    @Binding var saturation: Double
    @Binding var brightness: Double

    var body: some View {
        GeometryReader { geo in
            let trackWidth = geo.size.width - 40  // 20pt padding each side

            VStack(spacing: 20) {
                ChromaSlider(
                    value:      $hue,
                    trackWidth: trackWidth,
                    label:      "hue",
                    unit:       "°",
                    display:    Int(hue * 360),
                    track: LinearGradient(
                        colors: stride(from: 0.0, to: 1.01, by: 0.05).map {
                            Color(hue: $0, saturation: 0.85, brightness: 0.95)
                        },
                        startPoint: .leading, endPoint: .trailing
                    ),
                    thumbColor: Color(hue: hue, saturation: 0.85, brightness: 0.95)
                )

                ChromaSlider(
                    value:      $saturation,
                    trackWidth: trackWidth,
                    label:      "saturation",
                    unit:       "%",
                    display:    Int(saturation * 100),
                    track: LinearGradient(
                        colors: [
                            Color(hue: hue, saturation: 0,   brightness: brightness),
                            Color(hue: hue, saturation: 1.0, brightness: brightness)
                        ],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    thumbColor: Color(hue: hue, saturation: saturation, brightness: brightness)
                )

                ChromaSlider(
                    value:      $brightness,
                    trackWidth: trackWidth,
                    label:      "brightness",
                    unit:       "%",
                    display:    Int(brightness * 100),
                    track: LinearGradient(
                        colors: [
                            Color.black,
                            Color(hue: hue, saturation: saturation, brightness: 1)
                        ],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    thumbColor: Color(hue: hue, saturation: saturation, brightness: brightness)
                )
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 160)
    }
}

// MARK: - Individual Slider
struct ChromaSlider<Track: ShapeStyle>: View {
    @Binding var value:      Double
    var trackWidth:          CGFloat
    var label:               String
    var unit:                String
    var display:             Int
    var track:               Track
    var thumbColor:          Color

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 10, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.35))
                Spacer()
                Text("\(display)\(unit)")
                    .font(.system(size: 10, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
            }

            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 5)
                    .fill(track)
                    .frame(height: 10)

                // Thumb
                Circle()
                    .fill(thumbColor)
                    .frame(width: 22, height: 22)
                    .shadow(color: .black.opacity(0.4), radius: 3)
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .offset(x: CGFloat(value) * trackWidth - 11)
            }
            .frame(width: trackWidth)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        value = max(0, min(1, v.location.x / trackWidth))
                    }
            )
        }
    }
}
