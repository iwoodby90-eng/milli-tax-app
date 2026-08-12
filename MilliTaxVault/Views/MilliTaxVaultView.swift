import SwiftUI

// MARK: - Color Extension
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
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Chrome Emblem View
struct ChromeEmblemView: View {
    var body: some View {
        ZStack {
            // Outer Cyan Glow Ring
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "00E5FF").opacity(0.6), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
            
            // Outer Metallic Bezel
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.9), Color(white: 0.2), Color(white: 0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 62, height: 62)
            
            // Inner Dark Metallic Core
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "121824"), Color(hex: "05070B")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 56, height: 56)
                .overlay(
                    Circle()
                        .stroke(Color(hex: "00E5FF"), lineWidth: 1.5)
                        .shadow(color: Color(hex: "00E5FF"), radius: 4)
                )
            
            // Center Metallic "M" Logo
            Text("M")
                .font(.system(size: 26, weight: .black, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(white: 0.7), Color(white: 0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 2)
        }
    }
}

// MARK: - Milli Chrome Nav Bar
struct MilliChromeNavBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        ZStack {
            // Chrome metallic background
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
                // Left tabs
                ForEach(0..<2) { i in
                    Button(action: { selectedTab = i }) {
                        VStack(spacing: 4) {
                            Image(systemName: i == 0 ? "house.fill" : "location.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(selectedTab == i ? Color(hex: "00E5FF") : Color(hex: "8E92A0"))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                
                // Center M Button — ChromeEmblemView
                Spacer()
                ChromeEmblemView()
                    .offset(y: -16)
                Spacer()
                
                // Right tabs
                ForEach(2..<4) { i in
                    Button(action: { selectedTab = i }) {
                        VStack(spacing: 4) {
                            Image(systemName: i == 2 ? "chart.bar.fill" : "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(selectedTab == i ? Color(hex: "00E5FF") : Color(hex: "8E92A0"))
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
                    .fill(Color(hex: "00E5FF").opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(hex: "00E5FF"))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text(date)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "8E92A0"))
            }
            Spacer()
            Text(amount)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(hex: "00E5FF"))
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
            // Background
            Color(hex: "0A0D14")
                .ignoresSafeArea()
            
            // Subtle radial glow at top
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
                    // MARK: Header
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
                                .foregroundStyle(Color(hex: "8E92A0"))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // MARK: Gauge Ring
                    ZStack {
                        // Background ring
                        Circle()
                            .stroke(Color(white: 0.15), lineWidth: 14)
                            .frame(width: 220, height: 220)
                        
                        // Active neon ring
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                AngularGradient(
                                    colors: [Color(hex: "00E5FF"), Color(hex: "00E5FF").opacity(0.4)],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 14, lineCap: .round)
                            )
                            .frame(width: 220, height: 220)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: Color(hex: "00E5FF").opacity(0.8), radius: 12, x: 0, y: 0)
                            .animation(.easeInOut(duration: 1.4), value: progress)
                        
                        // Center content
                        VStack(spacing: 4) {
                            Text("$3,120")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("saved")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "8E92A0"))
                            Text("On track for Q3")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(hex: "00E5FF"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color(hex: "00E5FF").opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    .onAppear { progress = targetProgress }
                    
                    // MARK: Auto-Save Toggle Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "121620"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(LinearGradient(
                                        colors: [.cyan.opacity(0.3), .white.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ), lineWidth: 1)
                            )
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Auto-Save")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text("Save 30% of each payout automatically")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(hex: "8E92A0"))
                            }
                            Spacer()
                            Toggle("", isOn: $autoSaveEnabled)
                                .tint(Color(hex: "00E5FF"))
                                .labelsHidden()
                        }
                        .padding(20)
                    }
                    .padding(.horizontal, 20)
                    
                    // MARK: Recent Transfers Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "121620"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(LinearGradient(
                                        colors: [.cyan.opacity(0.3), .white.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ), lineWidth: 1)
                            )
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text("RECENT TRANSFERS")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color(hex: "8E92A0"))
                                    .tracking(1.5)
                                Spacer()
                                Text("See All")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color(hex: "00E5FF"))
                            }
                            .padding(.bottom, 16)
                            
                            TransferRow(title: "Auto-transfer \u{2014} Spark Payout", date: "Aug 10, 2026", amount: "+$78.16")
                            Divider().background(Color(white: 0.12)).padding(.vertical, 8)
                            TransferRow(title: "Auto-transfer \u{2014} DoorDash", date: "Aug 8, 2026", amount: "+$46.60")
                            Divider().background(Color(white: 0.12)).padding(.vertical, 8)
                            TransferRow(title: "Manual Transfer", date: "Aug 5, 2026", amount: "+$200.00")
                            Divider().background(Color(white: 0.12)).padding(.vertical, 8)
                            TransferRow(title: "Interest Earned", date: "Aug 1, 2026", amount: "+$2.14")
                        }
                        .padding(20)
                    }
                    .padding(.horizontal, 20)
                    
                    // Bottom padding for nav bar
                    Spacer().frame(height: 100)
                }
            }
            
            // MARK: Chrome Nav Bar
            MilliChromeNavBar(selectedTab: $selectedTab)
                .padding(.bottom, 24)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MilliTaxVaultView()
}
