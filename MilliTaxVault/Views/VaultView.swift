import SwiftUI

struct VaultView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // MARK: - Vault Balance Header
                VStack(spacing: 8) {
                    Text("VAULT BALANCE")
                        .sectionHeaderStyle()
                    
                    Text("$1,648")
                        .font(MilliFont.heroNumber)
                        .foregroundColor(.white)
                    
                    Text("63% of quarterly goal")
                        .font(MilliFont.caption)
                        .foregroundColor(MilliColors.cyan)
                }
                .padding(.top, 20)
                
                // MARK: - Progress Ring Card
                MilliCard {
                    VStack(spacing: 16) {
                        CircularProgressView(
                            progress: 0.63,
                            goal: "$2,580",
                            remaining: "$932"
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // MARK: - Quick Actions
                HStack(spacing: 16) {
                    Button(action: {}) {
                        Text("Add Funds")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(MilliColors.cyan)
                            )
                    }
                    
                    Button(action: {}) {
                        Text("Withdraw")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(white: 0.3), lineWidth: 1)
                            )
                    }
                }
                
                // MARK: - Reserve Status Card
                MilliCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Reserve Status")
                            .font(MilliFont.cardTitle)
                            .foregroundColor(.white)
                        
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Tax Ready Score")
                                    .font(MilliFont.caption)
                                    .foregroundColor(MilliColors.secondaryText)
                                
                                Text("85")
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .foregroundColor(MilliColors.green)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Est. Tax Owed")
                                    .font(MilliFont.caption)
                                    .foregroundColor(MilliColors.secondaryText)
                                
                                Text("$2,580")
                                    .font(MilliFont.subHeroNumber)
                                    .foregroundColor(.white)
                                
                                Text("This Quarter")
                                    .font(MilliFont.caption)
                                    .foregroundColor(MilliColors.secondaryText)
                            }
                        }
                    }
                }
                
                // MARK: - Recent Transfers
                VStack(alignment: .leading, spacing: 12) {
                    Text("RECENT TRANSFERS")
                        .sectionHeaderStyle()
                        .padding(.leading, 4)
                    
                    MilliCard {
                        VStack(spacing: 0) {
                            ForEach(Array(SampleData.transactions.enumerated()), id: \.element.id) { index, transaction in
                                TransactionRow(transaction: transaction)
                                
                                if index < SampleData.transactions.count - 1 {
                                    Divider()
                                        .background(Color(white: 0.15))
                                        .padding(.vertical, 12)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(MilliColors.cyan.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: transaction.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MilliColors.cyan)
            }
            
            // Title and subtitle
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.title)
                    .font(MilliFont.body)
                    .foregroundColor(.white)
                
                Text(transaction.subtitle)
                    .font(MilliFont.caption)
                    .foregroundColor(MilliColors.secondaryText)
            }
            
            Spacer()
            
            // Amount and date
            VStack(alignment: .trailing, spacing: 3) {
                Text(transaction.amount)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MilliColors.green)
                
                Text(transaction.date)
                    .font(MilliFont.caption)
                    .foregroundColor(MilliColors.secondaryText)
            }
        }
    }
}
