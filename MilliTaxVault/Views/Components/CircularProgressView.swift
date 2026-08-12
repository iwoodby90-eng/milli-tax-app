import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    let goal: String
    let remaining: String
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color(white: 0.12), lineWidth: 10)
                .frame(width: 180, height: 180)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [MilliColors.cyan, MilliColors.cyan.opacity(0.4)],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))
                .shadow(color: MilliColors.cyan.opacity(0.6), radius: 10)
            
            // Center content
            VStack(spacing: 6) {
                Text("Quarterly Goal")
                    .font(MilliFont.caption)
                    .foregroundColor(MilliColors.secondaryText)
                
                Text(goal)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Remaining")
                    .font(MilliFont.caption)
                    .foregroundColor(MilliColors.secondaryText)
                
                Text(remaining)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(MilliColors.amber)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2)) {
                animatedProgress = progress
            }
        }
    }
}
