import SwiftUI

struct OnboardingView: View {
    var onComplete: () -> Void
    
    @State private var currentPage: Int = 0
    
    private let slides: [(icon: String, headline: String, body: String)] = [
        (
            "arrow.down.circle.fill",
            "Every Payout,\non Autopilot.",
            "Milli automatically sets aside your taxes, tracks your mileage, and surfaces insights \u2014 so you can focus on what drives you."
        ),
        (
            "lock.shield.fill",
            "Know Your\nTax Position.",
            "Your Milli Tax Vault automatically reserves the right percentage from every payout. No spreadsheets. No surprises at tax time."
        ),
        (
            "location.fill",
            "Track Every\nMile.",
            "Milli captures every deductible mile automatically. At tax time, that\u2019s real money back in your pocket."
        )
    ]
    
    var body: some View {
        ZStack {
            Color(hex: "07090B")
                .ignoresSafeArea()
            
            VStack {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < 2 {
                        Button(action: { onComplete() }) {
                            Text("Skip")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(Color.white.opacity(0.5))
                        }
                        .padding(.trailing, 24)
                        .padding(.top, 16)
                    }
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<3, id: \.self) { index in
                        OnboardingSlideView(
                            icon: slides[index].icon,
                            headline: slides[index].headline,
                            body: slides[index].body
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Dot indicator
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color(hex: "00E5FF") : Color.white.opacity(0.2))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 24)
                
                // Get Started button (last slide only)
                if currentPage == 2 {
                    Button(action: { onComplete() }) {
                        Text("Get Started")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color(hex: "00E5FF"))
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                }
            }
        }
    }
}

struct OnboardingSlideView: View {
    let icon: String
    let headline: String
    let body: String
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                // Subtle cyan glow behind icon
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "00E5FF").opacity(0.12), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image(systemName: icon)
                    .font(.system(size: 72, weight: .regular))
                    .foregroundStyle(Color(hex: "00E5FF"))
            }
            
            Text(headline)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
            
            Text(body)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color(hex: "8E92A0"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
