import SwiftUI

struct MileageView: View {
    @State private var isTracking = false
    
    var body: some View {
        ZStack {
            Color.milliBackground.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    Text("MILEAGE")
                        .font(.system(size: 18, weight: .bold))
                        .tracking(3)
                        .chromeGradient()
                        .padding(.top, 16)
                    
                    Button(action: { isTracking.toggle() }) {
                        VStack(spacing: 12) {
                            Circle()
                                .fill(isTracking ? Color.milliRed.opacity(0.2) : Color.milliAccent.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: isTracking ? "stop.fill" : "location.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(isTracking ? .milliRed : .milliAccent)
                                )
                            
                            Text(isTracking ? "STOP TRACKING" : "START TRACKING")
                                .font(.system(size: 12, weight: .bold))
                                .tracking(2)
                                .foregroundColor(isTracking ? .milliRed : .milliAccent)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 20)
                    
                    HStack(spacing: 12) {
                        MileageStatCard(title: "TODAY", value: "42 mi", icon: "car.fill")
                        MileageStatCard(title: "THIS WEEK", value: "187 mi", icon: "calendar")
                        MileageStatCard(title: "THIS MONTH", value: "824 mi", icon: "chart.bar.fill")
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TAX DEDUCTION ESTIMATE")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(2)
                            .foregroundColor(.milliMuted)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("$1,547.25")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.milliGreen)
                                
                                Text("2,345 miles \u{00D7} $0.67/mi (2026 IRS rate)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.milliMuted)
                            }
                            Spacer()
                        }
                    }
                    .padding(16)
                    .milliCard()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("RECENT TRIPS")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(2)
                            .foregroundColor(.milliMuted)
                        
                        ForEach(mockTrips) { trip in
                            TripRow(trip: trip)
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

struct MileageStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.milliAccent)
            
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 8, weight: .medium))
                .tracking(1)
                .foregroundColor(.milliMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .milliCard()
    }
}

struct TripRow: View {
    let trip: MockTrip
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(trip.route)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                Text(trip.date)
                    .font(.system(size: 11))
                    .foregroundColor(.milliMuted)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(trip.miles)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Text(trip.deduction)
                    .font(.system(size: 11))
                    .foregroundColor(.milliGreen)
            }
        }
        .padding(.vertical, 6)
    }
}

struct MockTrip: Identifiable {
    let id = UUID()
    let route: String
    let date: String
    let miles: String
    let deduction: String
}

let mockTrips: [MockTrip] = [
    MockTrip(route: "Walmart \u{2192} Customer", date: "Today, 1:45 PM", miles: "8.2 mi", deduction: "$5.49"),
    MockTrip(route: "Home \u{2192} Walmart", date: "Today, 12:30 PM", miles: "4.1 mi", deduction: "$2.75"),
    MockTrip(route: "Sam's Club \u{2192} Customer", date: "Yesterday, 4:20 PM", miles: "12.6 mi", deduction: "$8.44"),
    MockTrip(route: "Home \u{2192} Sam's Club", date: "Yesterday, 3:15 PM", miles: "6.3 mi", deduction: "$4.22"),
]

#Preview {
    MileageView()
}
