import SwiftUI

// MARK: - MilliInsightCard — Milli AI Insight Row
// Compact insight with icon, label, text, and chevron using canonical M logo.

struct MilliInsightCard: View {
    let text: String
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 10) {
                // Milli canonical logo emblem circle
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [MilliColors.cyanGlow.opacity(0.18), MilliColors.cardBackground],
                                center: .center,
                                startRadius: 2,
                                endRadius: 16
                            )
                        )
                        .frame(width: 32, height: 32)
                        .overlay {
                            Circle().stroke(MilliColors.cyanGlow.opacity(0.35), lineWidth: 0.8)
                        }
                    
                    Image("MilliMLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .blendMode(.screen)
                        .shadow(color: MilliColors.cyanGlow.opacity(0.4), radius: 3)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("MILLI AI INSIGHT")
                        .font(MilliFont.sectionLabel)
                        .foregroundStyle(MilliColors.cyanGlow)
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
