import SwiftUI

struct PayoutsView: View {
    var body: some View {
        ZStack {
            Color.milliBackground.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    Text("PAYOUTS")
                        .font(.system(size: 18, weight: .bold))
                        .tracking(3)
                        .chromeGradient()
                        .padding(.top, 16)
                    
                    VStack(spacing: 12) {
                        Text("THIS WEEK")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(2)
                            .foregroundColor(.milliMuted)
                        
                        Text("$1,247.82")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 16) {
                            VStack(spacing: 2) {
                                Text("12")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Deliveries")
                                    .font(.system(size: 10))
                                    .foregroundColor(.milliMuted)
                            }
                            
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 1, height: 30)
                            
                            VStack(spacing: 2) {
                                Text("$103.98")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Avg/day")
                                    .font(.system(size: 10))
                                    .foregroundColor(.milliMuted)
                            }
                        }
                    }
                    .padding(20)
                    .milliCard()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("RECENT")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(2)
                            .foregroundColor(.milliMuted)
                        
                        ForEach(mockPayouts) { payout in
                            PayoutRow(payout: payout)
                        }
                    }
                    .padding(16)
                    .milliCard()
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

struct PayoutRow: View {
    let payout: MockPayout
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(payout.source)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Text(payout.date)
                    .font(.system(size: 11))
                    .foregroundColor(.milliMuted)
            }
            
            Spacer()
            
            Text(payout.amount)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.milliGreen)
        }
        .padding(.vertical, 8)
    }
}

struct MockPayout: Identifiable {
    let id = UUID()
    let source: String
    let date: String
    let amount: String
}

let mockPayouts: [MockPayout] = [
    MockPayout(source: "Spark Driver\u{2122}", date: "Today, 2:14 PM", amount: "+$312.64"),
    MockPayout(source: "Spark Driver\u{2122}", date: "Yesterday, 5:42 PM", amount: "+$198.31"),
    MockPayout(source: "Spark Driver\u{2122}", date: "Aug 5, 11:20 AM", amount: "+$245.87"),
    MockPayout(source: "Spark Driver\u{2122}", date: "Aug 4, 3:55 PM", amount: "+$156.22"),
    MockPayout(source: "Spark Driver\u{2122}", date: "Aug 3, 6:10 PM", amount: "+$334.78"),
]

#Preview {
    PayoutsView()
}
