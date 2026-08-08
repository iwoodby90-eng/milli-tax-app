import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            Color.milliBackground.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    headerSection
                    balanceSection
                    waveChartSection
                    statCardsGrid
                    milliAIInsightCard
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            Spacer()
            Text("MILLI")
                .font(.system(size: 18, weight: .bold))
                .tracking(3)
                .chromeGradient()
            Spacer()
        }
        .overlay(alignment: .trailing) {
            Button(action: {}) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Balance
    
    private var balanceSection: some View {
        VStack(spacing: 6) {
            Text("AVAILABLE TO SPEND")
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundColor(.milliMuted)
            
            Text("$1,365.42")
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(.white)
            
            Text("Updated just now")
                .font(.system(size: 12))
                .foregroundColor(.milliMuted)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Wave Chart
    
    private var waveChartSection: some View {
        WaveShape()
            .fill(
                LinearGradient(
                    colors: [Color.milliAccent.opacity(0.4), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 80)
            .padding(.horizontal, -16)
    }
    
    // MARK: - Stat Cards Grid
    
    private var statCardsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            latestPayoutCard
            taxVaultCard
            taxReadyScoreCard
            splitCard
        }
    }
    
    // MARK: - Latest Payout Card
    
    private var latestPayoutCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.milliAmber)
                Text("LATEST PAYOUT")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(.milliMuted)
            }
            
            Text("$312.64")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            HStack {
                Text("Today \u{00B7} Spark Driver\u{2122}")
                    .font(.system(size: 10))
                    .foregroundColor(.milliMuted)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(.milliMuted)
            }
        }
        .padding(14)
        .milliCard()
    }
    
    // MARK: - Tax Vault Card
    
    private var taxVaultCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MILLI TAX VAULT")
                .font(.system(size: 9, weight: .semibold))
                .tracking(1)
                .foregroundColor(.milliMuted)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("$5,284.17")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("23% of annual target")
                        .font(.system(size: 10))
                        .foregroundColor(.milliMuted)
                }
                
                Spacer()
                
                CircularProgressView(progress: 0.23, size: 36, lineWidth: 3)
            }
        }
        .padding(14)
        .milliCard()
    }
    
    // MARK: - Tax Ready Score Card
    
    private var taxReadyScoreCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TAX READY SCORE")
                .font(.system(size: 9, weight: .semibold))
                .tracking(1)
                .foregroundColor(.milliMuted)
            
            HStack(alignment: .bottom, spacing: 8) {
                Text("85")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.milliGreen)
                
                Text("Great")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.milliGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.milliGreen.opacity(0.15))
                    .cornerRadius(8)
                    .offset(y: -6)
            }
            
            Text("On track for tax season")
                .font(.system(size: 10))
                .foregroundColor(.milliMuted)
        }
        .padding(14)
        .milliCard()
    }
    
    // MARK: - Split Card
    
    private var splitCard: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundColor(.milliAccent)
                
                Text("$1,247.00")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Est. Jun 15")
                    .font(.system(size: 9))
                    .foregroundColor(.milliMuted)
            }
            .frame(maxWidth: .infinity)
            
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1)
                .padding(.vertical, 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "car.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.milliAccent)
                
                Text("2,345 mi")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Text("This quarter")
                    .font(.system(size: 9))
                    .foregroundColor(.milliMuted)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(14)
        .milliCard()
    }
    
    // MARK: - Milli AI Insight Card
    
    private var milliAIInsightCard: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.milliAccent)
                .frame(width: 4)
                .cornerRadius(2)
            
            Image(systemName: "cpu")
                .font(.system(size: 20))
                .foregroundColor(.milliAccent)
            
            Text("You\u{2019}re on pace to save $3,421 in taxes this year.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.milliMuted)
        }
        .padding(14)
        .frame(minHeight: 56)
        .milliCard()
    }
}

#Preview {
    HomeView()
}
