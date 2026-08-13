import SwiftUI

// MARK: - MilliInsightCard — Milli AI Insight Row
// Compact insight with icon, label, text, and chevron.

struct MilliInsightCard: View {
    let text: String
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 10) {
                // Milli icon circle
                ZStack {
                    Circle()
                        .fill(MilliColors.cyan.opacity(0.12))
                        .frame(width: 30, height: 30)
                    
                    Text("M")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(MilliColors.cyan)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("MILLI AI INSIGHT")
                        .font(MilliFont.sectionLabel)
                        .foregroundStyle(MilliColors.cyan)
                        .tracking(0.5)
                    
                    Text(text)
                        .font(MilliFont.insightBody)
                        .foregroundStyle(MilliColors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MilliColors.textMuted)
            }
            .padding(.horizontal, MilliLayout.cardPaddingH)
            .padding(.vertical, MilliLayout.cardPaddingV)
            .milliSurface()
        }
        .buttonStyle(.plain)
    }
}
