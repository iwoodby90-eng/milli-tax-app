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
        MilliMetalCard()
    }
}
