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
        ZStack(alignment: .top) {
            mapContent
            mapOverlay
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
                Annotation("You", coordinate: userCoord) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.electricBlueBright.opacity(0.18))
                            .frame(width: 54, height: 54)
                        Circle()
                            .fill(AppTheme.electricBlueBright)
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                    }
                }
            }

            if showNearbyTargets {
                ForEach(appState.discovery.mapOverlayResults) { prospect in
                    Annotation(prospect.name, coordinate: CLLocationCoordinate2D(latitude: prospect.latitude, longitude: prospect.longitude)) {
                        Button {
                            selectedProspect = prospect
                        } label: {
                            ProspectMapPin(title: prospect.name, category: prospect.category)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            ForEach(leadsWithPins) { lead in
                if let coordinate = lead.location.coordinate {
                    Annotation(lead.name, coordinate: coordinate) {
                        NavigationLink {
                            LeadDetailView(lead: lead)
                        } label: {
                            ClientMapPin(
                                title: lead.name,
                                isProximityEnabled: lead.location.pinReminderEnabled,
                                accent: lead.dealStage.pipelineColor
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

    private var mapOverlay: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                MapLegendChip(color: AppTheme.electricBlueBright, label: "Clients", icon: "person.fill")
                MapLegendChip(color: userCategory.accentColor, label: userCategory.rawValue, icon: userCategory.icon)
                Spacer()
                Button {
                    showNearbyTargets.toggle()
                    if showNearbyTargets { Task { await loadNearbyOverlay() } }
                } label: {
                    Label(showNearbyTargets ? "Targets On" : "Targets Off", systemImage: showNearbyTargets ? "eye.fill" : "eye.slash")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(showNearbyTargets ? AppTheme.tealGreen.opacity(0.85) : AppTheme.navyCard.opacity(0.85))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)

            GlassMapToolbar(items: [
                (icon: "person.2.fill", label: "Clients", value: "\(leadsWithPins.count)", color: AppTheme.electricBlueBright),
                (icon: userCategory.icon, label: "Targets", value: "\(appState.discovery.mapOverlayResults.count)", color: userCategory.accentColor),
                (icon: "arrow.triangle.turn.up.right.diamond.fill", label: "Route", value: "\(routeStops.count) stops", color: AppTheme.tealGreen)
            ])
            .padding(.horizontal, 14)

            if isLoadingOverlay {
                ProgressView("Finding \(userCategory.rawValue.lowercased()) nearby...")
                    .font(.caption)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }

            if !routeStops.isEmpty {
                MultiStopRouteButton(
                    stopCount: routeStops.count,
                    origin: appState.location.currentCoordinate,
                    stops: routeStops
                )
                .padding(.horizontal, 14)
            }

            Spacer()
        }
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
