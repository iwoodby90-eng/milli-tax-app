import SwiftUI

struct ChromeEmblemView: View {
    var size: CGFloat = 62
    
    var body: some View {
        ZStack {
            // Outer cyan glow
            Circle()
                .fill(RadialGradient(
                    colors: [MilliColor.cyan.opacity(0.5), .clear],
                    center: .center, startRadius: size * 0.3, endRadius: size * 0.6
                ))
                .frame(width: size + 18, height: size + 18)
            
            // Chrome outer bezel
            Circle()
                .fill(LinearGradient(
                    colors: [Color(white: 0.92), Color(white: 0.22), Color(white: 0.78), Color(white: 0.15), Color(white: 0.65)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: size, height: size)
            
            // Inner dark metallic core
            Circle()
                .fill(LinearGradient(
                    colors: [Color(hex: "121824"), Color(hex: "05070B")],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: size * 0.87, height: size * 0.87)
                .overlay(
                    Circle()
                        .stroke(MilliColor.cyan, lineWidth: 1.5)
                        .shadow(color: MilliColor.cyan, radius: 4)
                )
            
            // Milli M
            Text("M")
                .font(.system(size: size * 0.42, weight: .black, design: .serif))
                .foregroundStyle(LinearGradient(
                    colors: [.white, Color(white: 0.72), Color(white: 0.92)],
                    startPoint: .top, endPoint: .bottom
                ))
                .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 2)
        }
    }
}
