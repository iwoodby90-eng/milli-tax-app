import SwiftUI

// MARK: - Color Hex Initializer (single source of truth)

extension Color {
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

// MARK: - Milli Design System Colors

extension Color {
    static let milliBackground = Color(hex: "080810")
    static let milliCard = Color(hex: "12121C")
    static let milliCardBorder = Color(hex: "1E1E2E")
    static let milliCyan = Color(hex: "00B4FF")
    static let milliCyanLight = Color(hex: "7ADEFD")
    static let milliSuccess = Color(hex: "00FF88")
    static let milliWarning = Color(hex: "FFB800")
    static let milliError = Color(hex: "FF3B30")
    static let milliGreen = Color(hex: "00D68F")
    static let milliTextPrimary = Color.white
    static let milliTextSecondary = Color(white: 0.6)
    static let milliTextTertiary = Color(white: 0.4)
    static let milliChrome1 = Color(hex: "CCCCCC")
    static let milliChrome2 = Color(hex: "888888")
    static let milliChrome3 = Color(hex: "444444")
}

// MARK: - MilliCard Container

struct MilliCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(16)
            .background(Color.milliCard)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.milliCardBorder, lineWidth: 0.5)
            )
    }
}

// MARK: - Shared Page Header

struct MilliPageHeader: View {
    let title: String
    var subtitle: String? = nil
    var showBack: Bool = false
    var onBack: (() -> Void)? = nil

    var body: some View {
        HStack {
            if showBack {
                Button(action: { onBack?() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            if !showBack {
                Spacer()
            }
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.milliTextSecondary)
                }
            }
            Spacer()
            Button(action: {}) {
                Image(systemName: "bell")
                    .font(.system(size: 17))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat

    init(progress: Double, size: CGFloat = 60, lineWidth: CGFloat = 5) {
        self.progress = progress
        self.size = size
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.milliCyan, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.22, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Wave Shape (sparkline)

struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let mid = h * 0.5

        path.move(to: CGPoint(x: 0, y: mid))

        let segments = 4
        let segW = w / CGFloat(segments)

        for i in 0..<segments {
            let startX = CGFloat(i) * segW
            let endX = startX + segW
            let cy1 = i % 2 == 0 ? mid - h * 0.4 : mid + h * 0.3
            let cy2 = i % 2 == 0 ? mid + h * 0.2 : mid - h * 0.35

            path.addCurve(
                to: CGPoint(x: endX, y: mid),
                control1: CGPoint(x: startX + segW * 0.33, y: cy1),
                control2: CGPoint(x: startX + segW * 0.66, y: cy2)
            )
        }
        return path
    }
}
