import SwiftUI

// MARK: - AddRetirementAccountSheet — Add accounts to retirement projection
struct AddRetirementAccountSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let onAdd: (RetirementAccount) -> Void
    
    @State private var accountType: String = "Roth IRA"
    @State private var nickname: String = ""
    @State private var currentBalance: String = ""
    @State private var monthlyContribution: String = ""
    @State private var annualReturn: String = "7"
    
    private let accountTypes = [
        "Roth IRA",
        "Traditional IRA",
        "401(k)",
        "Pension",
        "Brokerage",
        "Other"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0A0C").ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Account Type
                        formSection(title: "ACCOUNT TYPE") {
                            Menu {
                                ForEach(accountTypes, id: \.self) { type in
                                    Button(type) { accountType = type }
                                }
                            } label: {
                                HStack {
                                    Text(accountType)
                                        .font(.system(size: 15))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundStyle(MilliColors.textMuted)
                                }
                                .fieldStyle()
                            }
                        }
                        
                        // Nickname
                        formSection(title: "ACCOUNT NICKNAME") {
                            TextField("e.g. Fidelity 401k", text: $nickname)
                                .font(.system(size: 15))
                                .foregroundStyle(.white)
                                .fieldStyle()
                        }
                        
                        // Current Balance
                        formSection(title: "CURRENT BALANCE") {
                            HStack(spacing: 4) {
                                Text("$")
                                    .font(.system(size: 15))
                                    .foregroundStyle(MilliColors.textSecondary)
                                TextField("0", text: $currentBalance)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 15))
                                    .foregroundStyle(.white)
                            }
                            .fieldStyle()
                        }
                        
                        // Monthly Contribution
                        formSection(title: "MONTHLY CONTRIBUTION") {
                            HStack(spacing: 4) {
                                Text("$")
                                    .font(.system(size: 15))
                                    .foregroundStyle(MilliColors.textSecondary)
                                TextField("0", text: $monthlyContribution)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 15))
                                    .foregroundStyle(.white)
                            }
                            .fieldStyle()
                        }
                        
                        // Expected Annual Return
                        formSection(title: "EXPECTED ANNUAL RETURN (%)") {
                            HStack(spacing: 4) {
                                TextField("7", text: $annualReturn)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 15))
                                    .foregroundStyle(.white)
                                Text("%")
                                    .font(.system(size: 15))
                                    .foregroundStyle(MilliColors.textSecondary)
                            }
                            .fieldStyle()
                        }
                        
                        // Add to Projection button
                        Button(action: addAccount) {
                            Text("Add to Projection")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(MilliColors.obsidian)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(MilliColors.cyan)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, MilliLayout.screenMargin)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Add Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MilliColors.cyan)
                }
            }
        }
        .presentationDetents([.large])
    }
    
    private func formSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(MilliColors.textSecondary)
                .tracking(0.5)
            content()
        }
    }
    
    private func addAccount() {
        let balance = Double(currentBalance) ?? 0
        let contrib = Double(monthlyContribution) ?? 0
        let returnRate = (Double(annualReturn) ?? 7) / 100.0
        let name = nickname.isEmpty ? accountType : nickname
        
        let account = RetirementAccount(
            name: name,
            type: accountType,
            currentBalance: balance,
            monthlyContribution: contrib,
            annualReturn: returnRate
        )
        
        onAdd(account)
        dismiss()
    }
}

// MARK: - Field Style Modifier
private struct FieldStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(hex: "12141A"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
    }
}

extension View {
    fileprivate func fieldStyle() -> some View {
        modifier(FieldStyleModifier())
    }
}

#Preview {
    AddRetirementAccountSheet { _ in }
}
