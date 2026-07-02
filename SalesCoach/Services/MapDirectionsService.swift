import CoreLocation
import MapKit

enum MapDirectionsService {
    static func drivingETA(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async -> String? {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile

        do {
            let response = try await MKDirections(request: request).calculate()
            guard let route = response.routes.first else { return nil }
            let minutes = max(1, Int(round(route.expectedTravelTime / 60)))
            let miles = route.distance / 1609.34
            if miles >= 0.1 {
                return "\(minutes) min · \(String(format: "%.1f", miles)) mi"
            }
            return "\(minutes) min drive"
        } catch {
            return nil
        }
    }

    static func loadETAs(for stops: [RouteStop], from origin: CLLocationCoordinate2D?) async -> [String: String] {
        guard let origin else { return [:] }
        var results: [String: String] = [:]
        for stop in stops.prefix(8) {
            guard let latitude = stop.lead.location.latitude,
                  let longitude = stop.lead.location.longitude else { continue }
            let destination = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            if let eta = await drivingETA(from: origin, to: destination) {
                results[stop.id] = eta
            }
        }
        return results
    }
}
