import SwiftUI

// MARK: - TreeOfLifeView — Life Events + Financial Journey Timeline
struct TreeOfLifeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showAddSheet = false
    @State private var visibleNodes: Set<Int> = []
    
    private let events: [LifeEvent] = [
        .init(category: .emergencyFund, title: "Emergency Fund", date: "Jan 2024", description: "6-month cushion fully funded.", isCompleted: true),
        .init(category: .education, title: "MBA Program", date: "May 2024", description: "Tuition paid. Zero student debt.", isCompleted: true),
        .init(category: .businessLaunch, title: "LLC Formation", date: "Sep 2024", description: "Milli Tax Services launched.", isCompleted: true),
        .init(category: .homePurchase, title: "First Home", date: "Mar 2025", description: "Down payment target: $60,000.", isCompleted: false),
        .init(category: .marriage, title: "Wedding", date: "Oct 2025", description: "Budget: $35,000. Savings on track.", isCompleted: false),
        .init(category: .child, title: "First Child", date: "2027", description: "529 plan opened. Monthly auto-deposit.", isCompleted: false),
        .init(category: .retirement, title: "Early Retirement", date: "2050", description: "Target: $2.5M portfolio at age 55.", isCompleted: false),
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "0A0A0C").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Timeline content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(Array(events.enumerated()), id: \.offset) { index, event in
                            timelineNode(event: event, index: index, isLast: index == events.count - 1)
                                .opacity(visibleNodes.contains(index) ? 1 : 0)
                                .offset(x: visibleNodes.contains(index) ? 0 : -20)
                                .animation(
                                    .easeOut(duration: 0.4).delay(Double(index) * 0.15),
                                    value: visibleNodes.contains(index)
                                )
                        }
                        
                        // Add Event Button
                        addEventButton
                            .padding(.top, 24)
                            .padding(.bottom, 100)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .onAppear {
            // Animate nodes in sequentially
            for index in events.indices {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.15) {
                    visibleNodes.insert(index)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddLifeEventSheet()
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image("MilliWordmark")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 18)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(MilliColors.textSecondary)
                }
            }
            
            Text("Tree of Life")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
            
            Text("Your financial journey, visualized.")
                .font(.system(size: 14))
                .foregroundStyle(MilliColors.textSecondary)
        }
        .padding(.horizontal, MilliLayout.screenMargin)
        .padding(.top, 60)
        .padding(.bottom, 12)
    }
    
    // MARK: - Timeline Node
    private func timelineNode(event: LifeEvent, index: Int, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Left: vertical line + node circle
            VStack(spacing: 0) {
                // Node circle
                ZStack {
                    if event.isCompleted {
                        Circle()
                            .fill(MilliColors.cyan)
                            .frame(width: 28, height: 28)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(hex: "0A0A0C"))
                    } else {
                        Circle()
                            .stroke(MilliColors.cyan.opacity(0.6), lineWidth: 2)
                            .frame(width: 28, height: 28)
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                            .foregroundStyle(MilliColors.cyan.opacity(0.7))
                    }
                }
                
                // Connecting line (except last)
                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [MilliColors.cyan.opacity(0.6), MilliColors.cyan.opacity(0.2)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 28)
            
            // Right: event card
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: event.category.icon)
                        .font(.system(size: 13))
                        .foregroundStyle(MilliColors.cyan)
                    
                    Text(event.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11))
                        .foregroundStyle(MilliColors.textMuted)
                }
                
                Text(event.date)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(MilliColors.cyan.opacity(0.8))
                
                Text(event.description)
                    .font(.system(size: 12))
                    .foregroundStyle(MilliColors.textSecondary)
                    .lineLimit(2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: "12141A"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, MilliLayout.screenMargin)
        .padding(.bottom, 16)
    }
    
    // MARK: - Add Event Button
    private var addEventButton: some View {
        Button(action: { showAddSheet = true }) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                Text("Add Life Event")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(MilliColors.obsidian)
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(MilliColors.cyan)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, MilliLayout.screenMargin)
    }
}

// MARK: - Life Event Model
struct LifeEvent: Identifiable {
    let id = UUID()
    let category: LifeEventCategory
    let title: String
    let date: String
    let description: String
    let isCompleted: Bool
}

enum LifeEventCategory {
    case homePurchase
    case marriage
    case businessLaunch
    case education
    case child
    case retirement
    case emergencyFund
    
    var icon: String {
        switch self {
        case .homePurchase: return "house.fill"
        case .marriage: return "heart.fill"
        case .businessLaunch: return "briefcase.fill"
        case .education: return "book.fill"
        case .child: return "figure.2.and.child"
        case .retirement: return "car.fill"
        case .emergencyFund: return "shield.fill"
        }
    }
}

#Preview {
    TreeOfLifeView()
}
