import SwiftUI

// MARK: - Full Spectrum Hue Ring
struct HueRing: View {
    var lineWidth: CGFloat = 24
    var opacity: Double    = 1.0

    var body: some View {
        GeometryReader { geo in
            let size   = min(geo.size.width, geo.size.height)
            let radius = (size / 2) - lineWidth / 2

            Canvas { ctx, canvasSize in
                let center  = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                let steps   = 360
                let dAngle  = (2 * Double.pi) / Double(steps)

                for i in 0..<steps {
                    let startAngle = Double(i) * dAngle - .pi / 2
                    let endAngle   = startAngle + dAngle + 0.01   // tiny overlap avoids gaps

                    var path = Path()
                    path.addArc(center: center,
                                radius: radius,
                                startAngle: .radians(startAngle),
                                endAngle:   .radians(endAngle),
                                clockwise: false)

                    let hue = Double(i) / Double(steps)
                    ctx.stroke(path,
                               with: .color(Color(hue: hue, saturation: 0.85, brightness: 0.95)
                                                .opacity(opacity)),
                               style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                }
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Sweep Arc (for timer)
struct SweepArc: View {
    var progress: Double    // 1.0 = full, 0.0 = empty
    var color: Color
    var lineWidth: CGFloat  = 24
    var backgroundColor: Color = Color.white.opacity(0.06)

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(backgroundColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // Progress
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
        }
    }
}

// MARK: - Clock Hand
struct ClockHand: View {
    var angle: Double          // degrees
    var length: CGFloat        // fraction of radius, 0…1
    var width: CGFloat
    var color: Color
    var hasDot: Bool = false

    var body: some View {
        GeometryReader { geo in
            let size   = min(geo.size.width, geo.size.height)
            let radius = size / 2
            let handLen = radius * length

            ZStack {
                Rectangle()
                    .fill(color)
                    .frame(width: width, height: handLen)
                    .offset(y: -handLen / 2)
                    .rotationEffect(.degrees(angle + 90))

                if hasDot {
                    Circle()
                        .fill(color)
                        .frame(width: width * 2.5, height: width * 2.5)
                }
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Tick Marks
struct TickMarks: View {
    var body: some View {
        GeometryReader { geo in
            let size   = min(geo.size.width, geo.size.height)
            let radius = size / 2

            Canvas { ctx, canvasSize in
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)

                for i in 0..<60 {
                    let angle     = Double(i) / 60.0 * 2 * .pi - .pi / 2
                    let isMajor   = i % 5 == 0
                    let tickLen   = isMajor ? radius * 0.08 : radius * 0.04
                    let outerR    = radius - 2.0
                    let innerR    = outerR - tickLen

                    let x1 = center.x + outerR * cos(angle)
                    let y1 = center.y + outerR * sin(angle)
                    let x2 = center.x + innerR * cos(angle)
                    let y2 = center.y + innerR * sin(angle)

                    var path = Path()
                    path.move(to: CGPoint(x: x1, y: y1))
                    path.addLine(to: CGPoint(x: x2, y: y2))

                    ctx.stroke(path,
                               with: .color(Color.white.opacity(isMajor ? 0.5 : 0.2)),
                               style: StrokeStyle(lineWidth: isMajor ? 2 : 1, lineCap: .round))
                }
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
