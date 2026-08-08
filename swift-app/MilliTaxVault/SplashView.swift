import SwiftUI

struct SplashView: View {
    @State private var showMainApp = false
    
    @State private var phase1LeftOffset: CGFloat = -60
    @State private var phase1RightOffset: CGFloat = 60
    @State private var phase2DotScale: CGFloat = 1.0
    @State private var phase2DotOpacity: Double = 0
    @State private var phase3RingSize: CGFloat = 0
    @State private var phase3RingOpacity: Double = 0
    @State private var phase4LabelsOpacity: Double = 0
    @State private var phase4LabelsOffset: CGFloat = 8
    @State private var phase5LineWidth: CGFloat = 0
    @State private var phase5LineOpacity: Double = 0
    @State private var phase6CrossDissolve = false
    @State private var phase6TextOpacity: Double = 0
    @State private var phase6ProgressWidth: CGFloat = 0
    @State private var displayedText = ""
    @State private var phase7Opacity: Double = 1.0
    
    private let typewriterText = "App Initializing..."
    
    var body: some View {
        if showMainApp {
            ContentView()
                .preferredColorScheme(.dark)
        } else {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if !phase6CrossDissolve {
                    logoAnimationView
                } else {
                    bootScreenView
                }
            }
            .opacity(phase7Opacity)
            .preferredColorScheme(.dark)
            .onAppear {
                startAnimationSequence()
            }
        }
    }
    
    // MARK: - Logo Animation (Phases 1-5)
    
    private var logoAnimationView: some View {
        ZStack {
            // Phase 5: Radiating lines
            ForEach(0..<8, id: \.self) { i in
                Rectangle()
                    .fill(Color(hex: "C0C0C0"))
                    .frame(width: phase5LineWidth, height: 1)
                    .offset(x: phase5LineWidth / 2)
                    .rotationEffect(.degrees(Double(i) * 45))
                    .opacity(phase5LineOpacity)
            }
            
            // Phase 3: Expanding ring
            Circle()
                .stroke(Color.milliAccent.opacity(0.6), lineWidth: 2)
                .frame(width: phase3RingSize, height: phase3RingSize)
                .opacity(phase3RingOpacity)
            
            // Phase 4: Labels
            VStack {
                Text("TAX")
                    .font(.caption)
                    .tracking(4)
                    .foregroundColor(.milliAccent)
                    .offset(y: -50)
                
                Spacer().frame(height: 100)
                
                HStack(spacing: 80) {
                    Text("MILES")
                        .font(.caption)
                        .tracking(4)
                        .foregroundColor(.milliAccent)
                    
                    Text("WEALTH")
                        .font(.caption)
                        .tracking(4)
                        .foregroundColor(.milliAccent)
                }
                .offset(y: 30)
            }
            .opacity(phase4LabelsOpacity)
            .offset(y: phase4LabelsOffset)
            
            // Phase 1: Split M letter
            HStack(spacing: 0) {
                Text("M")
                    .font(.system(size: 120, weight: .black))
                    .chromeGradient()
                    .frame(width: 40, alignment: .trailing)
                    .clipped()
                    .offset(x: phase1LeftOffset)
                
                Text("M")
                    .font(.system(size: 120, weight: .black))
                    .chromeGradient()
                    .frame(width: 40, alignment: .leading)
                    .clipped()
                    .offset(x: phase1RightOffset)
            }
            
            // Phase 2: Glowing dot
            Circle()
                .fill(Color.milliAccent)
                .frame(width: 8, height: 8)
                .shadow(color: .milliAccent, radius: 8)
                .scaleEffect(phase2DotScale)
                .opacity(phase2DotOpacity)
        }
    }
    
    // MARK: - Boot Screen (Phase 6)
    
    private var bootScreenView: some View {
        VStack(spacing: 20) {
            Text("MILLI TAX VAULT")
                .font(.system(size: 32, weight: .bold))
                .chromeGradient()
            
            Text(displayedText)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.milliMuted)
                .frame(height: 20)
            
            GeometryReader { geo in
                Capsule()
                    .fill(Color.milliAccent)
                    .frame(width: phase6ProgressWidth * geo.size.width, height: 2)
            }
            .frame(height: 2)
            .padding(.horizontal, 60)
        }
        .opacity(phase6TextOpacity)
    }
    
    // MARK: - Animation Sequence
    
    private func startAnimationSequence() {
        // Phase 1: M halves slide in (0.0 - 0.8s)
        withAnimation(.easeOut(duration: 0.8)) {
            phase1LeftOffset = 0
            phase1RightOffset = 0
        }
        
        // Phase 2: Glowing dot (0.7 - 1.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            phase2DotOpacity = 1.0
            withAnimation(.easeInOut(duration: 0.15).repeatCount(3, autoreverses: true)) {
                phase2DotScale = 1.5
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.2)) {
                    phase2DotOpacity = 0
                    phase2DotScale = 1.0
                }
            }
        }
        
        // Phase 3: Expanding ring (1.0 - 1.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            phase3RingOpacity = 1.0
            withAnimation(.easeOut(duration: 0.6)) {
                phase3RingSize = 160
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    phase3RingOpacity = 0
                }
            }
        }
        
        // Phase 4: Labels appear (1.4 - 2.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeOut(duration: 0.6)) {
                phase4LabelsOpacity = 1.0
                phase4LabelsOffset = 0
            }
        }
        
        // Phase 5: Radiating lines (2.2 - 2.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            phase5LineOpacity = 0.8
            withAnimation(.easeOut(duration: 0.4)) {
                phase5LineWidth = UIScreen.main.bounds.width * 0.4
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.2)) {
                    phase5LineOpacity = 0
                }
            }
        }
        
        // Phase 6: Cross-dissolve to boot screen (2.8 - 3.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.easeInOut(duration: 0.3)) {
                phase6CrossDissolve = true
            }
            withAnimation(.easeIn(duration: 0.4)) {
                phase6TextOpacity = 1.0
            }
            startTypewriter()
            withAnimation(.easeInOut(duration: 0.8)) {
                phase6ProgressWidth = 1.0
            }
        }
        
        // Phase 7: Fade out and transition (3.8 - 4.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) {
            withAnimation(.easeInOut(duration: 0.4)) {
                phase7Opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showMainApp = true
            }
        }
    }
    
    private func startTypewriter() {
        displayedText = ""
        let characters = Array(typewriterText)
        for (index, character) in characters.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                displayedText += String(character)
            }
        }
    }
}

#Preview {
    SplashView()
}
