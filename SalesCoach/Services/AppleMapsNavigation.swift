import CoreLocation
import MapKit
import SwiftUI
import UIKit

enum AppleMapsNavigation {
    static func openDirections(
        name: String,
        latitude: Double,
        longitude: Double,
        from origin: CLLocationCoordinate2D? = nil
    ) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        destination.name = name.isEmpty ? "Destination" : name

        let launchOptions: [String: Any] = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ]

        if let origin {
            let source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
            source.name = "Current Location"
            MKMapItem.openMaps(with: [source, destination], launchOptions: launchOptions)
        } else {
            destination.openInMaps(launchOptions: launchOptions)
        }
    }

    static func openDirections(to lead: Lead, from origin: CLLocationCoordinate2D? = nil) {
        if let latitude = lead.location.latitude, let longitude = lead.location.longitude {
            openDirections(
                name: lead.company.isEmpty ? lead.name : lead.company,
                latitude: latitude,
                longitude: longitude,
                from: origin
            )
            return
        }

        let query = lead.location.displayAddress.isEmpty
            ? (lead.company.isEmpty ? lead.name : lead.company)
            : lead.location.displayAddress
        openSearch(query: query, from: origin)
    }

    static func openDirections(to prospect: DiscoveredProspect, from origin: CLLocationCoordinate2D? = nil) {
        openDirections(
            name: prospect.name,
            latitude: prospect.latitude,
            longitude: prospect.longitude,
            from: origin
        )
    }

    static func openSearch(query: String, from origin: CLLocationCoordinate2D? = nil) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        Task { @MainActor in
            guard let item = try? await MKLocalSearch(request: request).start().mapItems.first else { return }
            let launchOptions: [String: Any] = [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ]
            if let origin {
                let source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
                source.name = "Current Location"
                MKMapItem.openMaps(with: [source, item], launchOptions: launchOptions)
            } else {
                item.openInMaps(launchOptions: launchOptions)
            }
        }
    }
}

struct AppleMapsNavigateButton: View {
    let title: String
    let name: String
    let latitude: Double
    let longitude: Double
    var origin: CLLocationCoordinate2D? = nil
    var style: Style = .primary

    enum Style {
        case primary
        case compact
    }

    var body: some View {
        Button {
            AppleMapsNavigation.openDirections(
                name: name,
                latitude: latitude,
                longitude: longitude,
                from: origin
            )
        } label: {
            switch style {
            case .primary:
                Label(title, systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
                    .background(AppTheme.tealGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            case .compact:
                Label(title, systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.tealGreen)
            }
        }
        .buttonStyle(.plain)
    }
}
