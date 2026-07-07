import MapKit
import SwiftUI

struct CRMMapView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showNearbyTargets = true
    @State private var selectedProspect: DiscoveredProspect?
    @State private var isLoadingOverlay = false

    private var leadsWithPins: [Lead] {
        appState.crm.leads.filter { $0.location.hasCoordinates }
    }

    private var userCategory: SalesCategory {
        appState.auth.currentUser?.salesCategory ?? .b2bServices
    }

    private var routeStops: [RouteStop] {
        RoutePlannerService.planRoute(from: appState.location.currentCoordinate, leads: appState.crm.leads)
    }

    var body: some View {
        VStack(spacing: 0) {
            mapContent
                .frame(minHeight: 320)

            mapControlPanel
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.borderColor(for: colorScheme), lineWidth: 1)
        )
        .shadow(color: AppTheme.electricBlue.opacity(colorScheme == .dark ? 0.15 : 0.08), radius: 20, y: 10)
        .onAppear {
            Task { await refreshMap() }
        }
        .sheet(item: $selectedProspect) { prospect in
            ProspectLockSheet(prospect: prospect) { lead in
                _ = appState.crm.addLead(lead)
                selectedProspect = nil
            }
        }
    }

    private var mapContent: some View {
        Map(position: $cameraPosition) {
            if let userCoord = appState.location.currentCoordinate {
                Annotation("", coordinate: userCoord, anchor: .center) {
                    MapUserPin()
                }
            }

            if showNearbyTargets {
                ForEach(appState.discovery.mapOverlayResults) { prospect in
                    Annotation("", coordinate: CLLocationCoordinate2D(latitude: prospect.latitude, longitude: prospect.longitude), anchor: .bottom) {
                        Button {
                            selectedProspect = prospect
                        } label: {
                            MapCategoryPin(category: prospect.category)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            ForEach(leadsWithPins) { lead in
                if let coordinate = lead.location.coordinate {
                    Annotation("", coordinate: coordinate, anchor: .bottom) {
                        NavigationLink {
                            LeadDetailView(lead: lead)
                        } label: {
                            MapClientPin(
                                accent: lead.dealStage.pipelineColor,
                                isProximityEnabled: lead.location.pinReminderEnabled
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }

    private var mapControlPanel: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    MapLegendChip(color: AppTheme.electricBlueBright, label: "Clients", icon: "person.fill")
                    MapLegendChip(color: userCategory.accentColor, label: userCategory.rawValue, icon: userCategory.icon)
                    Button {
                        showNearbyTargets.toggle()
                        if showNearbyTargets { Task { await loadNearbyOverlay() } }
                    } label: {
                        Label(showNearbyTargets ? "Targets On" : "Targets Off", systemImage: showNearbyTargets ? "eye.fill" : "eye.slash")
                            .font(.caption.bold())
                            .foregroundStyle(showNearbyTargets ? AppTheme.tealGreen : AppTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(showNearbyTargets ? AppTheme.tealGreen.opacity(0.15) : AppTheme.navyCard)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
            }
            .padding(.top, 12)

            GlassMapToolbar(items: [
                (icon: "person.2.fill", label: "Clients", value: "\(leadsWithPins.count)", color: AppTheme.electricBlueBright),
                (icon: userCategory.icon, label: "Targets", value: "\(appState.discovery.mapOverlayResults.count)", color: userCategory.accentColor),
                (icon: "arrow.triangle.turn.up.right.diamond.fill", label: "Route", value: "\(routeStops.count) stops", color: AppTheme.tealGreen)
            ])
            .padding(.horizontal, 14)

            if isLoadingOverlay {
                ProgressView("Finding \(userCategory.rawValue.lowercased()) nearby...")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.bottom, 4)
            }

            if !routeStops.isEmpty {
                MultiStopRouteButton(
                    stopCount: routeStops.count,
                    origin: appState.location.currentCoordinate,
                    stops: routeStops
                )
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            } else {
                Spacer(minLength: 0)
                    .frame(height: 4)
            }
        }
        .background(AppTheme.elevatedBackground(for: colorScheme).opacity(0.95))
    }

    private func refreshMap() async {
        if let coordinate = await appState.location.ensureCurrentLocation() {
            centerMap(on: coordinate)
            if showNearbyTargets {
                await loadNearbyOverlay()
            }
        } else if let first = leadsWithPins.first, let coord = first.location.coordinate {
            centerMap(on: coord)
        }
    }

    private func loadNearbyOverlay() async {
        var coordinate = appState.location.currentCoordinate
        if coordinate == nil {
            coordinate = await appState.location.ensureCurrentLocation()
        }
        guard let coordinate else { return }
        isLoadingOverlay = true
        await appState.discovery.loadMapOverlay(category: userCategory, near: coordinate)
        isLoadingOverlay = false
    }

    private func centerMap(on coordinate: CLLocationCoordinate2D) {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
            )
        )
    }
}

struct MapUserPin: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.electricBlueBright.opacity(0.18))
                .frame(width: 44, height: 44)
            Circle()
                .fill(AppTheme.electricBlueBright)
                .frame(width: 16, height: 16)
                .overlay(Circle().stroke(.white, lineWidth: 2))
        }
        .accessibilityLabel("Your location")
    }
}

struct MapClientPin: View {
    let accent: Color
    let isProximityEnabled: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.22))
                .frame(width: 40, height: 40)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [accent, accent.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
                .shadow(color: accent.opacity(0.4), radius: 4, y: 2)
            Image(systemName: isProximityEnabled ? "bell.fill" : "person.fill")
                .font(.caption2.bold())
                .foregroundStyle(.white)
        }
        .accessibilityLabel("Client pin")
    }
}

struct MapCategoryPin: View {
    let category: SalesCategory

    var body: some View {
        ZStack {
            Circle()
                .stroke(category.accentColor.opacity(0.35), lineWidth: 2)
                .frame(width: 38, height: 38)
            Circle()
                .fill(category.accentColor)
                .frame(width: 30, height: 30)
            Image(systemName: category.icon)
                .font(.caption2.bold())
                .foregroundStyle(.white)
        }
        .accessibilityLabel("Target pin")
    }
}
