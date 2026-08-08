import SwiftUI

struct MoreView: View {
    var body: some View {
        ZStack {
            Color.milliBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                MilliPageHeader(title: "More")

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        moreRow(icon: "person.circle.fill", label: "Profile & Settings", color: .white)
                        moreRow(icon: "sparkles", label: "Milli AI Assistant", color: .milliCyan)
                        moreRow(icon: "doc.text.fill", label: "Export Reports", color: .white)
                        moreRow(icon: "folder.fill", label: "Tax Documents", color: .white)
                        moreRow(icon: "questionmark.circle.fill", label: "Help & Support", color: .white)
                        moreRow(icon: "info.circle.fill", label: "About Milli", color: .white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
        }
    }

    private func moreRow(icon: String, label: String, color: Color) -> some View {
        MilliCard {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 28)

                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.milliTextTertiary)
            }
        }
    }
}
