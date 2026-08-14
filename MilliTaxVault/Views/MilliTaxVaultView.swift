import SwiftUI

// MARK: - Milli Chrome Nav Bar (standalone reference view)
struct MilliChromeNavBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient(
                    colors: [Color(white: 0.22), Color(white: 0.10), Color(white: 0.18)],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(LinearGradient(
                            colors: [Color(white: 0.6), Color(white: 0.15), Color(white: 0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.6), radius: 20, x: 0, y: -4)
            
            HStack(spacing: 0) {
                ForEach(0..<2) { i in
                    Button(action: { selectedTab = i }) {
                        VStack(spacing: 4) {
                            Image(systemName: i == 0 ? "house.fill" : "location.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(selectedTab == i ? MilliColor.cyan : MilliColor.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                
                Spacer()
                ChromeEmblemView()
                    .offset(y: -16)
                Spacer()
                
                ForEach(2..<4) { i in
                    Button(action: { selectedTab = i }) {
                        VStack(spacing: 4) {
                            Image(systemName: i == 2 ? "chart.bar.fill" : "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(selectedTab == i ? MilliColor.cyan : MilliColor.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .frame(height: 80)
        .padding(.horizontal, 16)
    }
}

// MARK: - Transfer Row
struct TransferRow: View {
    let title: String
    let date: String
    let amount: String
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(MilliColor.cyan.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(MilliColor.cyan)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text(date)
                    .font(.system(size: 12))
                    .foregroundStyle(MilliColor.textMuted)
            }
            Spacer()
            Text(amount)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(MilliColor.cyan)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Main View
struct MilliTaxVaultView: View {
    @State private var selectedTab: Int = 0
    @State private var autoSaveEnabled: Bool = true
    @State private var progress: CGFloat = 0
    let targetProgress: CGFloat = 0.75
    
    var body: some View {
        ZStack(alignment: .bottom) {
            MilliColor.obsidian
                .ignoresSafeArea()
            
            RadialGradient(
                colors: [Color(hex: "001F3F").opacity(0.6), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()
            .frame(height: 300)
            .frame(maxHeight: .infinity, alignment: .top)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    HStack {
                        Button(action: {}) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        Text("Tax Vault")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                        Button(action: {}) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 20))
                                .foregroundStyle(MilliColor.textMuted)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    ZStack {
                        Circle()
                            .stroke(Color(white: 0.15), lineWidth: 14)
                            .frame(width: 220, height: 220)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                AngularGradient(
                                    colors: [MilliColor.cyan, MilliColor.cyan.opacity(0.4)],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 14, lineCap: .round)
                            )
                            .frame(width: 220, height: 220)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: MilliColor.cyan.opacity(0.8), radius: 12, x: 0, y: 0)
                            .animation(.easeInOut(duration: 1.4), value: progress)
                        
                        VStack(spacing: 4) {
                            Text("$3,120")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("saved")
                                .font(.system(size: 14))
                                .foregroundStyle(MilliColor.textSecondary)
                            Text("On track for Q3")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(MilliColor.cyan)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(MilliColor.cyan.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    .onAppear { progress = targetProgress }
                    
                    Spacer().frame(height: 100)
                }
            }
            
            MilliChromeNavBar(selectedTab: $selectedTab)
                .padding(.bottom, 24)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MilliTaxVaultView()
}
