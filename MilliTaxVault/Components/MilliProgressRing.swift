import SwiftUI

// MARK: - MilliProgressRing — Tax Ready Score Ring
// Circle().trim animated on appear. Score centered. Status label beneath.

struct MilliProgressRing: View {
    let score: Int
    let maxScore: Int
    let label: String
    var ringColor: Color = MilliColors.cyan
    var size: CGFloat = 56
    var lineWidth: CGFloat = 5
    
    @State private var animatedProgress: CGFloat = 0
    
    private var progress: CGFloat {
        CGFloat(score) / CGFloat(maxScore)
    }
    
    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress arc
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
            
            // Score number
            VStack(spacing: 1) {
                Text("\(score)")
                    .font(MilliFont.soraBold(size > 50 ? 22 : 18))
                    .foregroundStyle(.white)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animatedProgress = progress
            }
        }
    }
}
