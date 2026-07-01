import CoreLocation
import MapKit

enum DiscoveryRadius: Int, CaseIterable, Identifiable {
    case oneMile = 1609
    case threeMiles = 4828
    case fiveMiles = 8047
    case tenMiles = 16093

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .oneMile: "1 mi"
        case .threeMiles: "3 mi"
        case .fiveMiles: "5 mi"
        case .tenMiles: "10 mi"
        }
    }

    var meters: Double { Double(rawValue) }
}

@MainActor
@Observable
final class ProspectDiscoveryService {
    var results: [DiscoveredProspect] = []
    var isSearching = false
    var errorMessage: String?
    var selectedCategory: SalesCategory?
    var lastSearchCoordinate: CLLocationCoordinate2D?
    var lastSearchLabel: String = ""

    func search(
        category: SalesCategory,
        companyQuery: String = "",
        near coordinate: CLLocationCoordinate2D,
        radius: DiscoveryRadius = .fiveMiles
    ) async {
        selectedCategory = category
        isSearching = true
        errorMessage = nil
        results = []
        lastSearchCoordinate = coordinate

        let trimmedCompany = companyQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        lastSearchLabel = trimmedCompany.isEmpty ? category.rawValue : trimmedCompany

        var queries = buildQueries(category: category, companyQuery: trimmedCompany)

        var combined: [DiscoveredProspect] = []
        for query in queries.prefix(6) {
            let found = await performSearch(
                query: query,
                category: category,
                companyQuery: trimmedCompany,
                coordinate: coordinate,
                radiusMeters: radius.meters
            )
            combined.append(contentsOf: found)
        }

        results = combined
            .uniqued(by: \.id)
            .filter { prospect in
                guard let distance = prospect.distanceMeters else { return true }
                return distance <= radius.meters
            }
            .sorted { ($0.distanceMeters ?? .infinity) < ($1.distanceMeters ?? .infinity) }

        if results.isEmpty {
            errorMessage = trimmedCompany.isEmpty
                ? "No \(category.rawValue.lowercased()) businesses found in this radius. Try widening the radius or another category."
                : "No \(category.rawValue.lowercased()) matches for \"\(trimmedCompany)\" nearby."
        }

        isSearching = false
    }

    private func buildQueries(category: SalesCategory, companyQuery: String) -> [String] {
        var queries: [String] = []

        if !companyQuery.isEmpty {
            queries.append(companyQuery)
            queries.append("\(companyQuery) \(category.searchQuery)")
        }

        queries.append(contentsOf: category.searchQueries)
        queries.append(contentsOf: category.quickSearchTerms)

        return Array(Set(queries))
    }

    private func performSearch(
        query: String,
        category: SalesCategory,
        companyQuery: String,
        coordinate: CLLocationCoordinate2D,
        radiusMeters: Double
    ) async -> [DiscoveredProspect] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: radiusMeters * 2,
            longitudinalMeters: radiusMeters * 2
        )
        request.resultTypes = [.pointOfInterest, .address]

        do {
            let response = try await MKLocalSearch(request: request).start()
            let origin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

            return response.mapItems.compactMap { item in
                guard let name = item.name, let location = item.placemark.location else { return nil }
                guard category.matches(mapItem: item, companyQuery: companyQuery) else { return nil }

                let matchedCategory = SalesCategory.bestMatch(for: item) ?? category

                let street = [item.placemark.subThoroughfare, item.placemark.thoroughfare]
                    .compactMap { $0 }
                    .joined(separator: " ")
                let city = [item.placemark.locality, item.placemark.administrativeArea]
                    .compactMap { $0 }
                    .joined(separator: ", ")

                return DiscoveredProspect(
                    id: "\(name)-\(location.coordinate.latitude)-\(location.coordinate.longitude)",
                    name: name,
                    address: street.isEmpty ? (city.isEmpty ? "Nearby location" : city) : street,
                    city: city,
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    phone: item.phoneNumber,
                    website: item.url?.absoluteString,
                    category: matchedCategory,
                    distanceMeters: origin.distance(from: location)
                )
            }
        } catch {
            return []
        }
    }

    func clearResults() {
        results = []
        selectedCategory = nil
        lastSearchCoordinate = nil
        lastSearchLabel = ""
    }
}

private extension Array {
    func uniqued<ID: Hashable>(by keyPath: KeyPath<Element, ID>) -> [Element] {
        var seen = Set<ID>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}
