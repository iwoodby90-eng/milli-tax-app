import SwiftUI

struct SplashView: View {
    var onComplete: () -> Void
    
    @State private var emblemScale: CGFloat = 0.3
    @State private var contentOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            Color(hex: "07090B")
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                
                ChromeEmblemView(size: 120)
                    .scaleEffect(emblemScale)
                
                VStack(spacing: 12) {
                    Text("MILLI")
                        .font(.system(size: 42, weight: .bold, design: .default))
                        .tracking(8)
                        .foregroundStyle(.white)
                    
                    Text("Money, Made Intelligent.")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .italic()
                        .foregroundStyle(Color(hex: "8E92A0"))
                    
                    Rectangle()
                        .fill(Color(hex: "00E5FF"))
                        .frame(width: 60, height: 2)
                        .padding(.top, 8)
                }
                .opacity(contentOpacity)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                emblemScale = 1.0
            }
            
            withAnimation(.easeInOut(duration: 0.5).delay(0.4)) {
                contentOpacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                onComplete()
            }
        }
    }
}

#Preview {
    SplashView(onComplete: {})
}
