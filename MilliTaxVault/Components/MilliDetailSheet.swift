import SwiftUI

// MARK: - MilliDetailSheet — Shared detail sheet for chevron actions
struct MilliDetailSheet: View {
    let title: String
    
    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "0A0A0C").ignoresSafeArea())
    }
}

#Preview {
    MilliDetailSheet(title: "Detail")
}
