import MapKit
import SwiftUI

struct CRMMapView: View {
    @Environment(AppState.self) private var appState

    private var leadsWithPins: [Lead] {
        appState.crm.leadsWithLocations()
    }

    private var defaultRegion: MKCoordinateRegion {
        if let first = leadsWithPins.first, let coord = first.location.coordinate {
            return MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08))
        }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        )
    }

    var body: some View {
        Map(initialPosition: .region(defaultRegion)) {
            ForEach(leadsWithPins) { lead in
                if let coordinate = lead.location.coordinate {
                    Annotation(lead.name, coordinate: coordinate) {
                        NavigationLink {
                            LeadDetailView(lead: lead)
                        } label: {
                            VStack(spacing: 2) {
                                ZStack {
                                    Circle()
                                        .fill(lead.location.pinReminderEnabled ? AppTheme.tealGreen : AppTheme.electricBlueBright)
                                        .frame(width: 36, height: 36)
                                    Image(systemName: lead.location.pinReminderEnabled ? "bell.fill" : "mappin.circle.fill")
                                        .foregroundStyle(.white)
                                        .font(.caption)
                                }
                                Text(lead.name)
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.navyCard)
                                    .clipShape(Capsule())
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if let userCoord = appState.location.currentCoordinate {
                Annotation("You", coordinate: userCoord) {
                    Circle()
                        .fill(AppTheme.electricBlueBright.opacity(0.3))
                        .frame(width: 18, height: 18)
                        .overlay(Circle().stroke(AppTheme.electricBlueBright, lineWidth: 2))
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .overlay(alignment: .top) {
            if leadsWithPins.isEmpty {
                Text("Add GPS locations to your leads to see them on the map.")
                    .font(.caption)
                    .padding(10)
                    .background(AppTheme.navyCard.opacity(0.9))
                    .clipShape(Capsule())
                    .padding(.top, 12)
            }
        }
    }
}
