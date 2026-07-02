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

    static func openMultiStopRoute(stops: [RouteStop], from origin: CLLocationCoordinate2D?) {
        let mappable = stops.filter { $0.lead.location.hasCoordinates }
        guard !mappable.isEmpty else { return }

        var items: [MKMapItem] = []
        if let origin {
            let source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
            source.name = "Current Location"
            items.append(source)
        }

        for stop in mappable.prefix(10) {
            guard let latitude = stop.lead.location.latitude,
                  let longitude = stop.lead.location.longitude else { continue }
            let item = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)))
            item.name = stop.lead.company.isEmpty ? stop.lead.name : stop.lead.company
            items.append(item)
        }

        guard items.count >= (origin == nil ? 1 : 2) else { return }

        let launchOptions: [String: Any] = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ]
        MKMapItem.openMaps(with: items, launchOptions: launchOptions)
    }

    static func openMultiStopRoute(leads: [Lead], from origin: CLLocationCoordinate2D?) {
        let stops = leads.enumerated().compactMap { index, lead -> RouteStop? in
            guard lead.location.hasCoordinates else { return nil }
            return RouteStop(id: lead.id, lead: lead, order: index + 1, distanceMeters: nil)
        }
        openMultiStopRoute(stops: stops, from: origin)
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
        case hero
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
                    .padding(.vertical, 13)
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(
                            colors: [AppTheme.tealGreen, AppTheme.successGreen],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: AppTheme.tealGreen.opacity(0.35), radius: 10, y: 4)
            case .compact:
                Label(title, systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.tealGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.tealGreen.opacity(0.12))
                    .clipShape(Capsule())
            case .hero:
                Label(title, systemImage: "map.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(.white)
                    .background(AppTheme.brandGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: AppTheme.electricBlue.opacity(0.35), radius: 14, y: 6)
            }
        }
        .buttonStyle(.plain)
    }
}

struct MultiStopRouteButton: View {
    let stopCount: Int
    let origin: CLLocationCoordinate2D?
    let stops: [RouteStop]

    var body: some View {
        Button {
            AppleMapsNavigation.openMultiStopRoute(stops: stops, from: origin)
        } label: {
            VStack(spacing: 6) {
                Label("Open Full Route in Apple Maps", systemImage: "point.topleft.down.curvedto.point.bottomright.up.fill")
                    .font(.headline)
                Text("\(stopCount) stops · driving directions with waypoints")
                    .font(.caption)
                    .opacity(0.88)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(AppTheme.brandGradient)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: AppTheme.electricBlue.opacity(0.35), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(stopCount == 0)
        .opacity(stopCount == 0 ? 0.5 : 1)
    }
}
