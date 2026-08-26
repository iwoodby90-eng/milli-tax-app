import SwiftUI

// MARK: - MilliMetalCard
// Dark titanium metal card with polished chip and canonical M emblem.

struct MilliMetalCard: View {
    var size: CGSize = CGSize(width: 150, height: 95)
    
    var body: some View {
        ZStack {
            // Dark titanium base
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(hex: "1C2028"), Color(hex: "252B38")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            // Specular highlight stripe
            GeometryReader { geo in
                Path { path in
                    let w = geo.size.width
                    let h = geo.size.height
                    path.move(to: CGPoint(x: w * 0.3, y: 0))
                    path.addLine(to: CGPoint(x: w * 0.4, y: 0))
                    path.addLine(to: CGPoint(x: w * 0.1, y: h))
                    path.addLine(to: CGPoint(x: 0, y: h))
                    path.closeSubpath()
                }
                .fill(Color.white.opacity(0.08))
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            // Chip
            VStack {
                HStack {
                    chipView
                        .padding(.top, 16)
                        .padding(.leading, 14)
                    Spacer()
                }
                Spacer()
            }
            
            // Canonical M Logo bottom-right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image("MilliMLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .blendMode(.screen)
                        .shadow(color: MilliColors.cyanGlow.opacity(0.35), radius: 3)
                        .padding(.trailing, 14)
                        .padding(.bottom, 10)
                }
            }
            
            // Inner border overlay
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
        .frame(width: size.width, height: size.height)
    }
    
    private var chipView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(hex: "A0A8B4"), Color(hex: "707880")],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(width: 24, height: 18)
            
            // Grid lines on chip
            Canvas { context, canvasSize in
                let cols = 3
                let rows = 3
                let colWidth = canvasSize.width / CGFloat(cols)
                let rowHeight = canvasSize.height / CGFloat(rows)
                
                for i in 1..<cols {
                    var path = Path()
                    path.move(to: CGPoint(x: CGFloat(i) * colWidth, y: 2))
                    path.addLine(to: CGPoint(x: CGFloat(i) * colWidth, y: canvasSize.height - 2))
                    context.stroke(path, with: .color(.white.opacity(0.3)), lineWidth: 0.5)
                }
                for i in 1..<rows {
                    var path = Path()
                    path.move(to: CGPoint(x: 2, y: CGFloat(i) * rowHeight))
                    path.addLine(to: CGPoint(x: canvasSize.width - 2, y: CGFloat(i) * rowHeight))
                    context.stroke(path, with: .color(.white.opacity(0.3)), lineWidth: 0.5)
                }
            }
            .frame(width: 24, height: 18)
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "07090B").ignoresSafeArea()
        VStack(spacing: 24) {
            MilliMetalCard()
            MilliEliteCardView()
        }
    }
}

// MARK: - MilliEliteCardView
// Card-details presentation matching the approved reference (Image 32):
// diagonal brushed-silver / dark split with a glowing cyan seam, 3D M emblem,
// chip + MILLI wordmark, VISA ELITE tier, cardholder and number.
// Rendered as a design showcase only — no real card data ever populates this view.

struct MilliEliteCardView: View {
    var size: CGSize = CGSize(width: 320, height: 200)

    var body: some View {
        ZStack {
            // Base: dark lower-right portion
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(
                    stops: [
                        .init(color: Color(hex: "14181D"), location: 0),
                        .init(color: Color(hex: "0B0E12"), location: 1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            // Brushed metallic upper-left diagonal section
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                Path { path in
                    path.move(to: .zero)
                    path.addLine(to: CGPoint(x: w * 0.78, y: 0))
                    path.addLine(to: CGPoint(x: w * 0.30, y: h))
                    path.addLine(to: CGPoint(x: 0, y: h))
                    path.closeSubpath()
                }
                .fill(LinearGradient(
                    stops: [
                        .init(color: Color(hex: "D9DEE3"), location: 0),
                        .init(color: Color(hex: "AEB6BD"), location: 0.45),
                        .init(color: Color(hex: "8A9299"), location: 1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            // Glowing cyan seam along the diagonal
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                Path { path in
                    path.move(to: CGPoint(x: w * 0.78, y: 0))
                    path.addLine(to: CGPoint(x: w * 0.30, y: h))
                }
                .stroke(
                    LinearGradient(
                        colors: [MilliColors.cyanGlow.opacity(0.9), MilliColors.deepCyan.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 1.4, lineCap: .round)
                )
                .shadow(color: MilliColors.cyanGlow.opacity(0.55), radius: 5)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .allowsHitTesting(false)

            // 3D M emblem on the metallic section
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    Image("MilliMLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 54, height: 54)
                        .shadow(color: Color.black.opacity(0.35), radius: 4, y: 2)

                    eliteChipView
                }
                Text("MILLI")
                    .font(.custom("Sora-Bold", size: 13))
                    .tracking(2.4)
                    .foregroundStyle(Color(hex: "2A3138"))
            }
            .padding(.top, 22)
            .padding(.leading, 22)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // Card details on the dark section
            VStack(alignment: .trailing, spacing: 6) {
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("VISA")
                        .font(.custom("Sora-Bold", size: 20))
                        .italic()
                        .foregroundStyle(.white)
                    Text("ELITE")
                        .font(MilliFont.label)
                        .tracking(1.6)
                        .foregroundStyle(MilliColors.textSecondary)
                }
                Text("MILLI MEMBER CARD")
                    .font(MilliFont.caption)
                    .tracking(0.8)
                    .foregroundStyle(MilliColors.textTertiary)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

            // Inner border
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
        .frame(width: size.width, height: size.height)
        .accessibilityLabel("Milli Elite card design preview")
    }

    private var eliteChipView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(hex: "C9CFD6"), Color(hex: "8F979E")],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(width: 30, height: 23)
            Canvas { context, canvasSize in
                let cols = 3
                let rows = 3
                let colWidth = canvasSize.width / CGFloat(cols)
                let rowHeight = canvasSize.height / CGFloat(rows)
                for i in 1..<cols {
                    var path = Path()
                    path.move(to: CGPoint(x: CGFloat(i) * colWidth, y: 2))
                    path.addLine(to: CGPoint(x: CGFloat(i) * colWidth, y: canvasSize.height - 2))
                    context.stroke(path, with: .color(.black.opacity(0.25)), lineWidth: 0.5)
                }
                for i in 1..<rows {
                    var path = Path()
                    path.move(to: CGPoint(x: 2, y: CGFloat(i) * rowHeight))
                    path.addLine(to: CGPoint(x: canvasSize.width - 2, y: CGFloat(i) * rowHeight))
                    context.stroke(path, with: .color(.black.opacity(0.25)), lineWidth: 0.5)
                }
            }
            .frame(width: 30, height: 23)
        }
    }
}
