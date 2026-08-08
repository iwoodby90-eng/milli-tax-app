import SwiftUI

// MARK: - Color Extensions

extension Color {
    static let milliBackground = Color(hex: "0A0A0F")
    static let milliCard = Color(hex: "12121A")
    static let milliAccent = Color(hex: "00B4FF")
    static let milliGreen = Color(hex: "00C853")
    static let milliRed = Color(hex: "FF3D57")
    static let milliAmber = Color(hex: "FFB800")
    static let milliMuted = Color(hex: "8B8BA0")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Legacy MilliColors enum (backward compat with existing views)

enum MilliColors {
    static let background = Color.milliBackground
    static let card = Color.milliCard
    static let accent = Color.milliAccent
    static let green = Color.milliGreen
    static let red = Color.milliRed
    static let muted = Color.milliMuted
}

// MARK: - Card Modifier

struct MilliCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.milliCard)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

extension View {
    func milliCard() -> some View {
        modifier(MilliCard())
    }
}

// MARK: - Chrome Gradient

struct ChromeGradient: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [Color(hex: "A0A0A0"), .white, Color(hex: "C0C0C0"), .white, Color(hex: "A0A0A0")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .mask(content)
    }
}

extension View {
    func chromeGradient() -> some View {
        modifier(ChromeGradient())
    }
}

// MARK: - Circular Progress

struct CircularProgressView: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    
    init(progress: Double, size: CGFloat = 36, lineWidth: CGFloat = 4) {
        self.progress = progress
        self.size = size
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.milliAccent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Wave Shape

struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height * 0.5
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        let segments = 4
        let segmentWidth = width / CGFloat(segments)
        
        for i in 0..<segments {
            let startX = CGFloat(i) * segmentWidth
            let endX = startX + segmentWidth
            let controlY1 = i % 2 == 0 ? midHeight - height * 0.4 : midHeight + height * 0.3
            let controlY2 = i % 2 == 0 ? midHeight + height * 0.2 : midHeight - height * 0.35
            
            path.addCurve(
                to: CGPoint(x: endX, y: midHeight),
                control1: CGPoint(x: startX + segmentWidth * 0.33, y: controlY1),
                control2: CGPoint(x: startX + segmentWidth * 0.66, y: controlY2)
            )
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}
