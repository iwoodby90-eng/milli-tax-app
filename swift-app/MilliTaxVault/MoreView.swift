import SwiftUI

struct MoreView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.milliBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        Text("MORE")
                            .font(.system(size: 18, weight: .bold))
                            .tracking(3)
                            .chromeGradient()
                            .padding(.top, 16)
                            .padding(.bottom, 24)
                        
                        // Primary navigation to additional screens
                        VStack(spacing: 0) {
                            MoreNavItem(icon: "lock.shield.fill", title: "Tax Vault", subtitle: "Automated tax savings", destination: TaxVaultView())
                            MoreNavItem(icon: "centsign.circle.fill", title: "Milli Cents", subtitle: "Round-up micro savings", destination: MilliCentsView())
                            MoreNavItem(icon: "creditcard.fill", title: "Expenses", subtitle: "Track & categorize spending", destination: ExpensesView())
                            MoreNavItem(icon: "chart.bar.doc.horizontal.fill", title: "Reports", subtitle: "Financial reports & analytics", destination: ReportsView())
                            MoreNavItem(icon: "building.columns.fill", title: "Retirement", subtitle: "IRA & retirement planning", destination: RetirementView())
                            MoreNavItem(icon: "banknote.fill", title: "Wealth Overview", subtitle: "Net worth & asset tracking", destination: WealthOverviewView())
                            MoreNavItem(icon: "leaf.fill", title: "Tree of Life", subtitle: "Financial growth visualization", destination: TreeOfLifeView())
                            MoreNavItem(icon: "brain.head.profile", title: "Milli AI", subtitle: "Your financial assistant", destination: MilliAIView())
                        }
                        .milliCard()
                        .padding(.horizontal, 16)
                        
                        Spacer().frame(height: 24)
                        
                        // Settings section
                        VStack(spacing: 0) {
                            MoreStaticItem(icon: "gearshape.fill", title: "Settings", subtitle: "Preferences & notifications")
                            MoreStaticItem(icon: "person.fill", title: "Profile", subtitle: "Account & identity")
                            MoreStaticItem(icon: "questionmark.circle.fill", title: "Help & Support", subtitle: "FAQs & contact")
                            MoreStaticItem(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", subtitle: nil, isDestructive: true)
                        }
                        .milliCard()
                        .padding(.horizontal, 16)
                        
                        Text("Milli Tax Vault v1.0.0")
                            .font(.system(size: 11))
                            .foregroundColor(.milliMuted)
                            .padding(.top, 24)
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct MoreNavItem<Destination: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.milliAccent)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.milliMuted)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.milliMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        
        Divider()
            .background(Color.white.opacity(0.06))
            .padding(.leading, 54)
    }
}

struct MoreStaticItem: View {
    let icon: String
    let title: String
    let subtitle: String?
    var isDestructive: Bool = false
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isDestructive ? .milliRed : .milliMuted)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isDestructive ? .milliRed : .white)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundColor(.milliMuted)
                    }
                }
                
                Spacer()
                
                if !isDestructive {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.milliMuted)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        
        if !isDestructive {
            Divider()
                .background(Color.white.opacity(0.06))
                .padding(.leading, 54)
        }
    }
}

#Preview {
    MoreView()
}
