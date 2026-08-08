import SwiftUI

struct SplashView: View {
    var onComplete: (() -> Void)? = nil
    
    // Animation state
    @State private var leftOffset: CGFloat = -300
    @State private var rightOffset: CGFloat = 300
    @State private var mergeScale: CGFloat = 0.85
    @State private var mergeOpacity: Double = 0
    @State private var bloomOpacity: Double = 0
    @State private var bloomScale: CGFloat = 0.3
    @State private var wordmarkOpacity: Double = 0
    @State private var wordmarkOffset: CGFloat = 20
    @State private var taglineOpacity: Double = 0
    @State private var bgOpacity: Double = 1
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "050508")
                .ignoresSafeArea()
            
            // Ambient background glow
            RadialGradient(
                colors: [Color(hex: "00B4FF").opacity(0.06), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()
            .opacity(mergeOpacity)
            
            VStack(spacing: 0) {
                Spacer()
                
                // M ANIMATION CONTAINER
                ZStack {
                    // Bloom flash on merge
                    Circle()
                        .fill(Color(hex: "00B4FF").opacity(0.15))
                        .frame(width: 180, height: 180)
                        .blur(radius: 30)
                        .scaleEffect(bloomScale)
                        .opacity(bloomOpacity)
                    
                    // LEFT HALF of M — slides in from left
                    LeftMShape()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FFFFFF"), Color(hex: "AAAAAA"), Color(hex: "CCCCCC")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 110)
                        .offset(x: leftOffset)
                    
                    // RIGHT HALF of M — slides in from right
                    RightMShape()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "CCCCCC"), Color(hex: "AAAAAA"), Color(hex: "FFFFFF")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 110)
                        .offset(x: rightOffset)
                    
                    // MERGED M — appears after halves converge
                    Text("M")
                        .font(.system(size: 110, weight: .black, design: .default))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: "7ADEFD"),
                                    Color(hex: "FFFFFF"),
                                    Color(hex: "00B4FF"),
                                    Color(hex: "FFFFFF"),
                                    Color(hex: "7ADEFD")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(hex: "00B4FF").opacity(0.6), radius: 20)
                        .shadow(color: Color.white.opacity(0.3), radius: 6)
                        .scaleEffect(mergeScale)
                        .opacity(mergeOpacity)
                }
                .frame(height: 130)
                
                Spacer().frame(height: 28)
                
                // WORDMARK
                VStack(spacing: 6) {
                    Text("MILLI")
                        .font(.system(size: 36, weight: .black, design: .default))
                        .tracking(12)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "FFFFFF"), Color(hex: "CCCCCC")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("TAX VAULT")
                        .font(.system(size: 13, weight: .semibold, design: .default))
                        .tracking(8)
                        .foregroundColor(Color(hex: "00B4FF"))
                        .shadow(color: Color(hex: "00B4FF").opacity(0.5), radius: 4)
                }
                .opacity(wordmarkOpacity)
                .offset(y: wordmarkOffset)
                
                Spacer().frame(height: 16)
                
                // TAGLINE
                Text("Your Financial Cockpit")
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .tracking(2)
                    .foregroundColor(Color(hex: "8B8BA0"))
                    .opacity(taglineOpacity)
                
                Spacer()
            }
        }
        .opacity(bgOpacity)
        .ignoresSafeArea()
        .onAppear { runAnimation() }
    }
    
    private func runAnimation() {
        // Phase 1: Slide halves in (0 → 0.6s)
        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
            leftOffset = 0
            rightOffset = 0
        }
        
        // Phase 2: Bloom flash (0.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.25)) {
                bloomOpacity = 1
                bloomScale = 1.4
            }
            withAnimation(.easeIn(duration: 0.3).delay(0.2)) {
                bloomOpacity = 0
            }
        }
        
        // Phase 3: Merged M appears (0.55s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                mergeOpacity = 1
                mergeScale = 1.0
                leftOffset = -300
                rightOffset = 300
            }
        }
        
        // Phase 4: Wordmark rises up (1.1s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.easeOut(duration: 0.5)) {
                wordmarkOpacity = 1
                wordmarkOffset = 0
            }
        }
        
        // Phase 5: Tagline (1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.4)) {
                taglineOpacity = 1
            }
        }
        
        // Phase 6: Fade to app (2.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            withAnimation(.easeInOut(duration: 0.5)) {
                bgOpacity = 0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) {
            onComplete?()
        }
    }
}

// Left half of the M letterform (angular, bold strokes)
struct LeftMShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: w * 0.3, y: 0))
        path.addLine(to: CGPoint(x: w, y: h * 0.55))
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: w * 0.65, y: h))
        path.addLine(to: CGPoint(x: w * 0.65, y: h * 0.72))
        path.addLine(to: CGPoint(x: w * 0.22, y: h * 0.22))
        path.addLine(to: CGPoint(x: w * 0.22, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}

// Right half of the M letterform (mirror)
struct RightMShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w * 0.7, y: 0))
        path.addLine(to: CGPoint(x: 0, y: h * 0.55))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: w * 0.35, y: h))
        path.addLine(to: CGPoint(x: w * 0.35, y: h * 0.72))
        path.addLine(to: CGPoint(x: w * 0.78, y: h * 0.22))
        path.addLine(to: CGPoint(x: w * 0.78, y: h))
        path.addLine(to: CGPoint(x: w, y: h))
        path.closeSubpath()
        return path
    }
}
