import SwiftUI

struct ContentView: View {
    @State private var selectedTab: MilliTab = .vault
    
    var body: some View {
        ZStack {
            // Background gradient
            MilliGradients.backgroundRadial
                .ignoresSafeArea()
            
            // Tab content
            VStack(spacing: 0) {
                // Active view
                Group {
                    switch selectedTab {
                    case .vault:
                        VaultView()
                    case .wealth:
                        WealthView()
                    case .activity:
                        ActivityView()
                    case .cockpit:
                        CockpitView()
                    }
                }
                .frame(maxHeight: .infinity)
                
                // Custom nav bar
                NavBar(selectedTab: $selectedTab)
            }
            
            // Floating AI button
            floatingAIButton
        }
    }
    
    // MARK: - Floating AI Button
    
    private var floatingAIButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(MilliGradients.aiButton)
                            .frame(width: 54, height: 54)
                        
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .shadow(color: MilliColors.cyan.opacity(0.5), radius: 16, x: 0, y: 4)
                }
                .offset(x: -20, y: -110)
            }
        }
    }
}
