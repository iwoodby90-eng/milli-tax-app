import SwiftUI
import MapKit

// MARK: - MileageView — Live Map + Trip Tracking
struct MileageView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var isTracking = false
    @State private var showQuarterDetail = false
    @State private var showMonthDetail = false
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 42.3314, longitude: -83.0458),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    
    var body: some View {
        VStack(spacing: 0) {
            // Top stats section (~45%)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: MilliLayout.sectionGap) {
                    headerSection
                    
                    // Mileage subtitle
                    VStack(spacing: 4) {
                        Text("Mileage")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Track your drives automatically.")
                            .font(.system(size: 14))
                            .foregroundStyle(MilliColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    statsSection
                }
            }
            .frame(maxHeight: UIScreen.main.bounds.height * 0.40)
            
            // Live Map (~55%)
            mapSection
        }
        .background(MilliColors.obsidian.ignoresSafeArea())
        .onAppear {
            locationManager.requestPermission()
            updateCameraToUser()
        }
        .onChange(of: locationManager.lastLocation) { _, newLocation in
            if let loc = newLocation, !isTracking {
                withAnimation {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: loc.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                        )
                    )
                }
            }
        }
    }
    
    // MARK: - Header (Centered MILLI + bell overlay)
    private var headerSection: some View {
        ZStack {
            // Centered wordmark
            Text("M I L L I")
                .font(.system(size: 18, weight: .semibold))
                .tracking(8)
                .foregroundColor(.white)
            
            // Bell icon right-aligned
            HStack {
                Spacer()
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                    Circle()
                        .fill(MilliColors.cyan)
                        .frame(width: 6, height: 6)
                        .offset(x: 2, y: -1)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 72)
        .padding(.bottom, 8)
    }
    
    // MARK: - Stats
    private var statsSection: some View {
        VStack(spacing: MilliLayout.sectionGap) {
            Button { showQuarterDetail = true } label: {
                mileageStatCard(icon: "car.fill", title: "This Quarter", value: "2,345 mi", subtitle: "$1,548 deduction")
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showQuarterDetail) { MilliDetailSheet(title: "This Quarter") }
            
            Button { showMonthDetail = true } label: {
                mileageStatCard(icon: "calendar", title: "This Month", value: "847 mi", subtitle: "$559 deduction")
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showMonthDetail) { MilliDetailSheet(title: "This Month") }
        }
        .padding(.horizontal, MilliLayout.screenMargin)
    }
    
    private func mileageStatCard(icon: String, title: String, value: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(MilliColors.cyan.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(MilliColors.cyan)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MilliColors.textSecondary)
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(MilliColors.textMuted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(MilliColors.textMuted)
        }
        .padding(.horizontal, MilliLayout.cardPaddingH)
        .padding(.vertical, MilliLayout.cardPaddingV)
        .milliSurface()
    }
    
    // MARK: - Map Section
    private var mapSection: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition) {
                UserAnnotation()
                
                if locationManager.routeCoordinates.count > 1 {
                    MapPolyline(coordinates: locationManager.routeCoordinates)
                        .stroke(Color(hex: "00E5FF"), lineWidth: 4)
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapPitchToggle()
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(MilliColors.cyan.opacity(0.4), lineWidth: 1)
            )
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
            
            // Start/Stop Trip Button
            tripButton
                .padding(.bottom, 20)
        }
    }
    
    // MARK: - Trip Button
    private var tripButton: some View {
        Button(action: toggleTracking) {
            HStack(spacing: 8) {
                Image(systemName: isTracking ? "stop.fill" : "location.fill")
                    .font(.system(size: 14, weight: .bold))
                Text(isTracking ? "Stop Trip" : "Start Trip")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(isTracking ? .white : MilliColors.obsidian)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isTracking ? Color(hex: "FF5252") : MilliColors.cyan)
            )
            .shadow(color: (isTracking ? Color(hex: "FF5252") : MilliColors.cyan).opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helpers
    private func toggleTracking() {
        isTracking.toggle()
        if isTracking {
            locationManager.startTracking()
        } else {
            locationManager.stopTracking()
        }
    }
    
    private func updateCameraToUser() {
        if let location = locationManager.lastLocation {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            )
        }
    }
}

#Preview {
    MileageView()
}
