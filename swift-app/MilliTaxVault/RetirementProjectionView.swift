import SwiftUI

// MARK: - Retirement Projection View

struct RetirementProjectionView: View {
    @State private var contributionPctDouble: Double = 15
    @State private var retirementAgeDouble: Double = 62
    
    private var contributionPct: Int { Int(contributionPctDouble) }
    private var retirementAge: Int { Int(retirementAgeDouble) }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                adjustYourPlanSection
                updatedProjectionCard
                projectionScenariosSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Color.milliBackground)
        .navigationTitle("Adjust Your Plan")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Adjust Your Plan Section
    
    private var adjustYourPlanSection: some View {
        VStack(spacing: 20) {
            // Contribution Percentage Slider
            VStack(spacing: 10) {
                HStack {
                    Text("Contribution Percentage")
                        .font(.callout)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(contributionPct)%")
                        .font(.headline)
                        .foregroundColor(.milliAccent)
                }
                
                Slider(value: $contributionPctDouble, in: 0...50, step: 1)
                    .tint(Color.milliAccent)
            }
            
            // Retirement Age Slider
            VStack(spacing: 10) {
                HStack {
                    Text("Retirement Age")
                        .font(.callout)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(retirementAge) years")
                        .font(.headline)
                        .foregroundColor(.milliAccent)
                }
                
                Slider(value: $retirementAgeDouble, in: 55...75, step: 1)
                    .tint(Color.milliAccent)
            }
        }
        .padding(16)
        .milliCard()
    }
    
    // MARK: - Updated Projection Card
    
    private var updatedProjectionCard: some View {
        VStack(spacing: 14) {
            Text("Updated Projection")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ProjectionRowItem(label: "Retirement Year", value: "2047", subLabel: "at age 62")
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            ProjectionRowItem(label: "Estimated Value", value: "$1,623,587", valueColor: .white)
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            ProjectionRowItem(label: "Total Contributions", value: "$455,100", valueColor: .white)
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            ProjectionRowItem(label: "Total Growth", value: "$1,168,487", valueColor: .milliGreen)
        }
        .padding(16)
        .milliCard()
    }
    
    // MARK: - Projection Scenarios Section
    
    private var projectionScenariosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Projection Scenarios")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                ScenarioCardView(
                    name: "Conservative",
                    returnRate: "6% return",
                    value: "$883,214",
                    isSelected: false
                )
                
                ScenarioCardView(
                    name: "Moderate",
                    returnRate: "7% return",
                    value: "$1,623,587",
                    isSelected: true
                )
                
                ScenarioCardView(
                    name: "Aggressive",
                    returnRate: "8% return",
                    value: "$2,881,996",
                    isSelected: false
                )
            }
        }
    }
}

// MARK: - Projection Row Item

struct ProjectionRowItem: View {
    let label: String
    let value: String
    var subLabel: String? = nil
    var valueColor: Color = .white
    
    var body: some View {
        HStack {
            Text(label)
                .font(.callout)
                .foregroundColor(.milliMuted)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(valueColor)
                if let subLabel = subLabel {
                    Text(subLabel)
                        .font(.caption2)
                        .foregroundColor(.milliMuted)
                }
            }
        }
    }
}

// MARK: - Scenario Card View

struct ScenarioCardView: View {
    let name: String
    let returnRate: String
    let value: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            Text(name)
                .font(.caption)
                .foregroundColor(.milliMuted)
            
            Text(returnRate)
                .font(.caption2)
                .foregroundColor(.milliMuted)
            
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(
            isSelected
                ? Color.milliAccent.opacity(0.1)
                : Color.milliCard
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isSelected ? Color.milliAccent : Color.white.opacity(0.08),
                    lineWidth: isSelected ? 2 : 1
                )
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RetirementProjectionView()
    }
    .preferredColorScheme(.dark)
}
