import SwiftUI

// MARK: - AddRetirementAccountSheet & Rollover Wizard
// Supports connecting past/current accounts (401k, Traditional IRA, Roth IRA, SEP-IRA, Brokerage)
// and merging them into the Milli Retirement Portfolio with direct ACATS rollover support.

public struct ConnectedExternalRetirementAccount: Identifiable, Codable, Equatable {
    public let id: String
    public let custodianName: String
    public let accountType: String
    public let nickname: String
    public var balance: Double
    public var monthlyContribution: Double
    public var annualReturnPercent: Double
    public var rolloverStatus: RolloverStatus
    public let accountMask: String

    public enum RolloverStatus: String, Codable, CaseIterable {
        case connected = "Connected & Merged"
        case transferInitiated = "Rollover In Progress"
        case completed = "ACATS Rollover Completed"

        public var badgeColor: Color {
            switch self {
            case .connected: return Color(hex: "00E5FF")
            case .transferInitiated: return Color(hex: "FFB800")
            case .completed: return Color(hex: "34C759")
            }
        }
    }

    public static let standardCustodians = [
        "Fidelity Investments",
        "Vanguard",
        "Charles Schwab",
        "Empower Retirement",
        "Principal Financial",
        "Betterment",
        "Robinhood Retirement",
        "Merrill Edge",
        "T. Rowe Price",
        "Other Custodian"
    ]
}

struct AddRetirementAccountSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let onAdd: (ConnectedExternalRetirementAccount) -> Void
    
    @State private var selectedCustodian: String = "Fidelity Investments"
    @State private var accountType: String = "401(k)"
    @State private var nickname: String = "Past Employer 401(k)"
    @State private var currentBalance: String = "34850"
    @State private var monthlyContribution: String = "250"
    @State private var annualReturn: String = "7.5"
    @State private var isDirectRollover: Bool = true
    @State private var accountMask: String = "8102"
    
    private let accountTypes = [
        "401(k)",
        "Traditional IRA",
        "Roth IRA",
        "SEP-IRA",
        "403(b)",
        "Brokerage / Taxable",
        "Pension"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "07090B").ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Custodian Institution
                        formSection(title: "PAST / CURRENT CUSTODIAN") {
                            Menu {
                                ForEach(ConnectedExternalRetirementAccount.standardCustodians, id: \.self) { inst in
                                    Button(inst) {
                                        selectedCustodian = inst
                                        if nickname.isEmpty || nickname.contains("401(k)") {
                                            nickname = "\(inst) \(accountType)"
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "building.columns.fill")
                                        .foregroundStyle(MilliColors.cyanGlow)
                                    Text(selectedCustodian)
                                        .font(.custom("Inter-Medium", size: 15))
                                        .foregroundStyle(MilliColors.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundStyle(MilliColors.textSecondary)
                                }
                                .fieldStyle()
                            }
                        }
                        
                        // Account Type
                        formSection(title: "ACCOUNT TYPE") {
                            Menu {
                                ForEach(accountTypes, id: \.self) { type in
                                    Button(type) {
                                        accountType = type
                                        nickname = "\(selectedCustodian) \(type)"
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(accountType)
                                        .font(.custom("Inter-Medium", size: 15))
                                        .foregroundStyle(MilliColors.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundStyle(MilliColors.textSecondary)
                                }
                                .fieldStyle()
                            }
                        }
                        
                        // Nickname & Mask
                        HStack(spacing: 12) {
                            formSection(title: "ACCOUNT NICKNAME") {
                                TextField("e.g. Fidelity 401(k)", text: $nickname)
                                    .font(.custom("Inter-Regular", size: 15))
                                    .foregroundStyle(MilliColors.textPrimary)
                                    .fieldStyle()
                            }
                            
                            formSection(title: "LAST 4") {
                                TextField("8102", text: $accountMask)
                                    .keyboardType(.numberPad)
                                    .font(.custom("Inter-SemiBold", size: 15))
                                    .foregroundStyle(MilliColors.textPrimary)
                                    .fieldStyle()
                                    .frame(width: 80)
                            }
                        }
                        
                        // Current Balance
                        formSection(title: "CURRENT BALANCE") {
                            HStack(spacing: 4) {
                                Text("$")
                                    .font(.custom("Sora-SemiBold", size: 16))
                                    .foregroundStyle(MilliColors.cyanGlow)
                                TextField("34850", text: $currentBalance)
                                    .keyboardType(.decimalPad)
                                    .font(.custom("Sora-SemiBold", size: 16))
                                    .foregroundStyle(MilliColors.textPrimary)
                            }
                            .fieldStyle()
                        }
                        
                        // Rollover & Merge Option
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ROLLOVER & MERGE STRATEGY")
                                .font(.custom("Inter-Bold", size: 11))
                                .tracking(0.5)
                                .foregroundStyle(MilliColors.textSecondary)
                            
                            Toggle(isOn: $isDirectRollover) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Initiate Direct ACATS Rollover")
                                        .font(.custom("Inter-SemiBold", size: 13))
                                        .foregroundStyle(MilliColors.textPrimary)
                                    Text("Consolidate directly into your Milli Retirement Account with zero tax penalties.")
                                        .font(.custom("Inter-Regular", size: 11))
                                        .foregroundStyle(MilliColors.textSecondary)
                                }
                            }
                            .tint(MilliColors.cyanGlow)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(MilliColors.graphiteSurface)
                                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 0.8))
                            )
                        }
                        
                        // Add / Merge Button
                        Button(action: submitAccount) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.triangle.merge")
                                Text(isDirectRollover ? "Connect & Rollover into Milli" : "Connect & Merge Balance")
                            }
                            .font(.custom("Inter-SemiBold", size: 15))
                            .foregroundStyle(MilliColors.blackGlass)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(MilliColors.cyanGlow)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, MilliSpacing.screenHorizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Connect Past Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MilliColors.cyanGlow)
                }
            }
        }
        .presentationDetents([.large])
    }
    
    private func formSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.custom("Inter-Bold", size: 11))
                .tracking(0.5)
                .foregroundStyle(MilliColors.textSecondary)
            content()
        }
    }
    
    private func submitAccount() {
        let bal = Double(currentBalance) ?? 0
        let contrib = Double(monthlyContribution) ?? 0
        let rate = Double(annualReturn) ?? 7.0
        
        let account = ConnectedExternalRetirementAccount(
            id: UUID().uuidString,
            custodianName: selectedCustodian,
            accountType: accountType,
            nickname: nickname.isEmpty ? "\(selectedCustodian) \(accountType)" : nickname,
            balance: bal,
            monthlyContribution: contrib,
            annualReturnPercent: rate,
            rolloverStatus: isDirectRollover ? .transferInitiated : .connected,
            accountMask: accountMask.isEmpty ? "8102" : accountMask
        )
        
        onAdd(account)
        dismiss()
    }
}

private struct FieldStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: "0C1015"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
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
