import MapKit
import SwiftUI

struct LeadLocationSection: View {
    @Environment(AppState.self) private var appState
    @Binding var location: LeadLocation
    @State private var isFetchingLocation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(AppTheme.electricBlueBright)
                Text("GPS Location")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
            }

            TextField("Location label (e.g. HQ, Office)", text: $location.locationLabel)
                .textFieldStyle(AppTextFieldStyle())

            TextField("Street address", text: $location.address)
                .textFieldStyle(AppTextFieldStyle())

            TextField("City", text: $location.city)
                .textFieldStyle(AppTextFieldStyle())

            SecondaryButton(title: isFetchingLocation ? "Getting location..." : "Use Current Location", icon: "location.fill") {
                captureCurrentLocation()
            }
            .disabled(isFetchingLocation)

            if location.hasCoordinates, let coordinate = location.coordinate {
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))) {
                    Marker(location.locationLabel.isEmpty ? "Lead" : location.locationLabel, coordinate: coordinate)
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude))
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textMuted)
            }

            Toggle(isOn: $location.pinReminderEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pin reminder")
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Notify me when I'm near this location")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .tint(AppTheme.electricBlueBright)
            .disabled(!location.hasCoordinates)

            if location.pinReminderEnabled {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reminder radius: \(Int(location.reminderRadiusMeters))m")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Slider(value: $location.reminderRadiusMeters, in: 100...1000, step: 50)
                        .tint(AppTheme.tealGreen)
                }
            }
        }
        .cardStyle()
    }

    private func captureCurrentLocation() {
        isFetchingLocation = true
        Task {
            if let coordinate = await appState.location.requestCurrentLocation() {
                if let geocoded = await appState.location.reverseGeocode(coordinate: coordinate) {
                    location.address = geocoded.address
                    location.city = geocoded.city
                }
                location.latitude = coordinate.latitude
                location.longitude = coordinate.longitude
            }
            isFetchingLocation = false
        }
    }
}
