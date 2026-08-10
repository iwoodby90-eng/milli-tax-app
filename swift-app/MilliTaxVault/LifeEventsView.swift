import SwiftUI

struct LifeEventsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: EventFilter = .upcoming
    
    enum EventFilter: String, CaseIterable {
        case upcoming = "Upcoming"
        case planned = "Planned"
        case completed = "Completed"
    }
    
    enum ImpactLevel: String {
        case high = "High Impact"
        case medium = "Medium Impact"
        case low = "Low Impact"
        
        var color: Color {
            switch self {
            case .high: return .milliError
            case .medium: return .milliWarning
            case .low: return .milliSuccess
            }
        }
    }
    
    struct LifeEvent: Identifiable {
        let id = UUID()
        let icon: String
        let name: String
        let date: String
        let cost: String
        let impact: ImpactLevel
        let filter: EventFilter
    }
    
    private let events: [LifeEvent] = [
        LifeEvent(icon: "heart.fill", name: "Marriage", date: "Jun 2027", cost: "$25,000", impact: .medium, filter: .upcoming),
        LifeEvent(icon: "house.fill", name: "House Purchase", date: "Dec 2028", cost: "$120,000", impact: .high, filter: .planned),
        LifeEvent(icon: "figure.and.child.holdinghands", name: "Child", date: "2029", cost: "$35,000", impact: .high, filter: .planned),
        LifeEvent(icon: "briefcase.fill", name: "Career Change", date: "TBD", cost: "Variable", impact: .medium, filter: .upcoming),
        LifeEvent(icon: "shield.fill", name: "Emergency Fund", date: "Ongoing", cost: "$15,000", impact: .low, filter: .upcoming),
    ]
    
    private var filteredEvents: [LifeEvent] {
        events.filter { $0.filter == selectedFilter }
    }
    
    var body: some View {
        ZStack {
            Color.milliBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with info button
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Life Events")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                // Filter Tabs
                HStack(spacing: 0) {
                    ForEach(EventFilter.allCases, id: \.self) { filter in
                        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedFilter = filter } }) {
                            VStack(spacing: 6) {
                                Text(filter.rawValue)
                                    .font(.system(size: 14, weight: selectedFilter == filter ? .semibold : .regular))
                                    .foregroundColor(selectedFilter == filter ? .milliCyan : .milliTextSecondary)
                                
                                Rectangle()
                                    .fill(selectedFilter == filter ? Color.milliCyan : Color.clear)
                                    .frame(height: 2)
                                    .cornerRadius(1)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        if filteredEvents.isEmpty {
                            VStack(spacing: 12) {
                                Spacer().frame(height: 40)
                                Image(systemName: "calendar")
                                    .font(.system(size: 36, weight: .thin))
                                    .foregroundColor(.milliTextTertiary)
                                Text("No \(selectedFilter.rawValue.lowercased()) events.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.milliTextSecondary)
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            ForEach(filteredEvents) { event in
                                MilliCard {
                                    HStack(spacing: 12) {
                                        Image(systemName: event.icon)
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.milliCyan)
                                            .frame(width: 40, height: 40)
                                            .background(Color.milliCyan.opacity(0.1))
                                            .cornerRadius(10)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(event.name)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(.white)
                                            
                                            HStack(spacing: 8) {
                                                Text(event.date)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.milliTextSecondary)
                                                
                                                Text("•")
                                                    .foregroundColor(.milliTextTertiary)
                                                
                                                Text(event.cost)
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 6) {
                                            Text(event.impact.rawValue)
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(event.impact.color)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 3)
                                                .background(event.impact.color.opacity(0.12))
                                                .cornerRadius(4)
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(.milliTextTertiary)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Add Life Event Button
                        Button(action: {}) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Add Life Event")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.milliCyan)
                            .cornerRadius(14)
                            .shadow(color: Color.milliCyan.opacity(0.3), radius: 12, x: 0, y: 4)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
    }
}
