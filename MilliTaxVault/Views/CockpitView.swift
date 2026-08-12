import SwiftUI

struct CockpitView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // MARK: - Profile Card
                MilliCard {
                    VStack(spacing: 16) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [MilliColors.cyan, Color(hex: "0066FF")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Text("IW")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        // Name
                        Text("Ian Woodby")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Badge
                        Text("Milli Pro")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(MilliColors.cyan)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(MilliColors.cyan.opacity(0.12))
                                    .overlay(
                                        Capsule()
                                            .stroke(MilliColors.cyan.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        
                        Text("Member since January 2026")
                            .font(MilliFont.caption)
                            .foregroundColor(MilliColors.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 20)
                
                // MARK: - Subscription Card
                MilliCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .foregroundColor(MilliColors.amber)
                            
                            Text("MILLI PRO")
                                .font(.system(size: 14, weight: .bold))
                                .tracking(1.2)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            FeatureRow(text: "Unlimited auto-transfers")
                            FeatureRow(text: "Smart tax optimization")
                            FeatureRow(text: "Priority support")
                        }
                        
                        Button(action: {}) {
                            Text("Manage Plan")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(MilliColors.cyan)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(MilliColors.cyan.opacity(0.5), lineWidth: 1)
                                )
                        }
                    }
                }
                
                // MARK: - App Settings
                SettingsSection(title: "APP", rows: [
                    SettingsRow(icon: "bell.fill", label: "Notifications", iconColor: MilliColors.cyan),
                    SettingsRow(icon: "lock.shield.fill", label: "Security", iconColor: MilliColors.green),
                    SettingsRow(icon: "paintbrush.fill", label: "Appearance", iconColor: MilliColors.amber)
                ])
                
                // MARK: - Tax Settings
                SettingsSection(title: "TAX", rows: [
                    SettingsRow(icon: "doc.text.fill", label: "Tax Profile", iconColor: MilliColors.cyan),
                    SettingsRow(icon: "chart.bar.doc.horizontal.fill", label: "Reports", iconColor: MilliColors.green),
                    SettingsRow(icon: "calendar.badge.clock", label: "Quarterly Reminders", iconColor: MilliColors.amber)
                ])
                
                // MARK: - Support
                SettingsSection(title: "SUPPORT", rows: [
                    SettingsRow(icon: "questionmark.circle.fill", label: "Help Center", iconColor: MilliColors.cyan),
                    SettingsRow(icon: "envelope.fill", label: "Contact Us", iconColor: MilliColors.green)
                ])
                
                // MARK: - Footer
                VStack(spacing: 20) {
                    Text("Milli Tax Vault v1.0.0")
                        .font(MilliFont.caption)
                        .foregroundColor(MilliColors.secondaryText)
                    
                    Button(action: {}) {
                        Text("Sign Out")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(MilliColors.red)
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(MilliColors.green)
            
            Text(text)
                .font(MilliFont.body)
                .foregroundColor(Color(white: 0.8))
        }
    }
}

// MARK: - Settings Section

struct SettingsSection: View {
    let title: String
    let rows: [SettingsRow]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .sectionHeaderStyle()
                .padding(.leading, 4)
            
            MilliCard {
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        SettingsRowView(row: row)
                        
                        if index < rows.count - 1 {
                            Divider()
                                .background(Color(white: 0.15))
                                .padding(.vertical, 12)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Settings Row View

struct SettingsRowView: View {
    let row: SettingsRow
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(row.iconColor.opacity(0.12))
                    .frame(width: 34, height: 34)
                
                Image(systemName: row.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(row.iconColor)
            }
            
            Text(row.label)
                .font(MilliFont.body)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(white: 0.3))
        }
    }
}
