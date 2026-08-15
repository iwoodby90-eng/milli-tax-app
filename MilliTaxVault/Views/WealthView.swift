import SwiftUI

// MARK: - WealthView — Investing, Retirement & Overview Hub
struct WealthView: View {
    @State private var selectedSegment: WealthSegment = .investing
    
    enum WealthSegment: String, CaseIterable {
        case investing = "Investing"
        case retirement = "Retirement"
        case overview = "Overview"
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: MilliLayout.sectionGap) {
                // Centered MILLI Header
                headerSection
                
                // Wealth subtitle
                VStack(spacing: 4) {
                    Text("Wealth")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Grow. Protect. Retire.")
                        .font(.system(size: 14))
                        .foregroundStyle(MilliColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                
                // Segment picker
                segmentPicker
                
                // Content based on segment
                switch selectedSegment {
                case .investing:
                    InvestingView()
                case .retirement:
                    RetirementView()
                case .overview:
                    WealthOverviewView()
                }
            }
            .padding(.bottom, 100)
        }
        .background(MilliColors.obsidian.ignoresSafeArea())
    }
    
    // MARK: - Header (Centered MILLI + bell overlay)
    private var headerSection: some View {
        ZStack {
            // Centered wordmark
            Text("M I L L I")
                .font(.system(size: 18, weight: .semibold))
                .tracking(8)
                .foregroundColor(.white)
            
            // Bell icon right-aligned
            HStack {
                Spacer()
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                    Circle()
                        .fill(MilliColors.cyan)
                        .frame(width: 6, height: 6)
                        .offset(x: 2, y: -1)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 72)
        .padding(.bottom, 8)
    }
    
    // MARK: - Segment Picker
    private var segmentPicker: some View {
        HStack(spacing: 0) {
            ForEach(WealthSegment.allCases, id: \.self) { segment in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSegment = segment
                    }
                }) {
                    Text(segment.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(selectedSegment == segment ? .white : MilliColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedSegment == segment
                            ? RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(MilliColors.cyan.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(MilliColors.cyan.opacity(0.3), lineWidth: 1)
                                )
                            : nil
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(hex: "12141A"))
        )
        .padding(.horizontal, MilliLayout.screenMargin)
    }
}

#Preview {
    WealthView()
}
