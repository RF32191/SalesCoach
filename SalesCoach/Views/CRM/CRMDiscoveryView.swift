import MapKit
import SwiftUI

struct CRMDiscoveryView: View {
    var initialCategory: SalesCategory? = nil

    var body: some View {
        CompanyDiscoveryView(initialCategory: initialCategory)
    }
}

struct CompanyDiscoveryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    var initialCategory: SalesCategory? = nil
    var initialSearch: String = ""

    @State private var selectedCategory: SalesCategory = .b2bServices
    @State private var companySearch = ""
    @State private var selectedRadius: DiscoveryRadius = .fiveMiles
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedProspect: DiscoveredProspect?
    @State private var lockedMessage: String?
    @State private var duplicateMessage: String?
    @State private var hasSearched = false

    var body: some View {
        VStack(spacing: 0) {
            if !appState.location.isLocationAuthorized {
                locationGate
            } else {
                discoveryControls
                mapSection
                resultsSection
            }
        }
        .appBackground()
        .navigationTitle("Company Finder")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let initialCategory {
                selectedCategory = initialCategory
            } else if let userCategory = appState.auth.currentUser?.salesCategory {
                selectedCategory = userCategory
            }
            if !initialSearch.isEmpty {
                companySearch = initialSearch
            }
            appState.location.requestAuthorization()
        }
        .sheet(item: $selectedProspect) { prospect in
            ProspectLockSheet(prospect: prospect) { lead in
                if appState.crm.addLead(lead) {
                    appState.teamGoals.recordNewLead()
                    if let userId = appState.auth.currentUser?.id {
                        appState.teamGoals.save(for: userId)
                    }
                    lockedMessage = "\(lead.company) added to your CRM pipeline."
                } else {
                    duplicateMessage = "\(lead.company) is already in your CRM."
                }
                selectedProspect = nil
            }
        }
        .alert("Client Added", isPresented: .constant(lockedMessage != nil)) {
            Button("OK") { lockedMessage = nil }
        } message: {
            Text(lockedMessage ?? "")
        }
        .alert("Already Added", isPresented: .constant(duplicateMessage != nil)) {
            Button("OK") { duplicateMessage = nil }
        } message: {
            Text(duplicateMessage ?? "")
        }
    }

    private var locationGate: some View {
        ScrollView {
            VStack(spacing: 20) {
                CRMGradientHeader(
                    title: "Find Companies Near You",
                    subtitle: "Lock your GPS location to discover and add sales targets on the map.",
                    icon: "location.fill",
                    accent: AppTheme.tealGreen
                )

                LocationPermissionCard(
                    status: appState.location.locationStatusMessage,
                    onEnable: { Task { await lockLocationAndSearch() } },
                    onOpenSettings: { appState.location.openSettingsIfNeeded() },
                    isDenied: appState.location.authorizationStatus == .denied || appState.location.authorizationStatus == .restricted
                )
            }
            .padding()
        }
    }

    private var discoveryControls: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Location Locked", systemImage: "location.fill")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.tealGreen)
                    Text(appState.location.currentAddressLabel ?? "Using your current GPS position")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                        .lineLimit(2)
                }
                Spacer()
                Button {
                    Task { await lockLocationAndSearch() }
                } label: {
                    Image(systemName: "location.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.tealGreen)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Sales Target Type")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))

                if appState.auth.currentUser?.salesCategory != nil {
                    HStack(spacing: 8) {
                        Image(systemName: selectedCategory.icon)
                            .foregroundStyle(selectedCategory.accentColor)
                        Text(selectedCategory.rawValue)
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                        Spacer()
                        Text("Your team vertical")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textMuted)
                    }
                    .padding(12)
                    .background(AppTheme.navyCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(SalesCategory.allCases) { category in
                                Button {
                                    selectedCategory = category
                                    Task { await runSearch() }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: category.icon)
                                        Text(category.rawValue)
                                    }
                                    .font(.caption.bold())
                                    .foregroundStyle(selectedCategory == category ? .white : AppTheme.primaryText(for: colorScheme))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == category ? category.accentColor : AppTheme.navyCard)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppTheme.textMuted)
                    TextField("Search company name...", text: $companySearch)
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                        .submitLabel(.search)
                        .onSubmit { Task { await runSearch() } }
                }
                .padding(12)
                .background(AppTheme.navyCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    Task { await runSearch() }
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.electricBlueBright)
                }
                .disabled(appState.discovery.isSearching)
            }

            HStack(spacing: 8) {
                Text("Radius")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
                ForEach(DiscoveryRadius.allCases) { radius in
                    Button {
                        selectedRadius = radius
                        if hasSearched { Task { await runSearch() } }
                    } label: {
                        Text(radius.label)
                            .font(.caption2.bold())
                            .foregroundStyle(selectedRadius == radius ? .white : AppTheme.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selectedRadius == radius ? AppTheme.electricBlue : AppTheme.navyCard)
                            .clipShape(Capsule())
                    }
                }
                Spacer()
            }

            notableTargetsSection
        }
        .padding()
        .background(AppTheme.elevatedBackground(for: colorScheme))
    }

    private var notableTargetsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Popular \(selectedCategory.rawValue) Targets")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(selectedCategory.notableCRMTargets, id: \.self) { brand in
                        Button {
                            companySearch = brand
                            Task { await runSearch() }
                        } label: {
                            Text(brand)
                                .font(.caption2.bold())
                                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(AppTheme.navyCard)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(selectedCategory.accentColor.opacity(0.35), lineWidth: 1)
                                )
                        }
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(selectedCategory.quickSearchTerms, id: \.self) { term in
                        Button {
                            companySearch = term
                            Task { await runSearch() }
                        } label: {
                            Label(term, systemImage: "magnifyingglass")
                                .font(.caption2)
                                .foregroundStyle(selectedCategory.accentColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(selectedCategory.accentColor.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private var mapSection: some View {
        Map(position: $cameraPosition) {
            if let userCoord = appState.location.currentCoordinate {
                Annotation("You", coordinate: userCoord) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.tealGreen.opacity(0.2))
                            .frame(width: 44, height: 44)
                        Circle()
                            .fill(AppTheme.tealGreen)
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                    }
                }
            }

            ForEach(appState.discovery.results) { prospect in
                Annotation(prospect.name, coordinate: CLLocationCoordinate2D(latitude: prospect.latitude, longitude: prospect.longitude)) {
                    Button {
                        selectedProspect = prospect
                    } label: {
                        VStack(spacing: 2) {
                            Circle()
                                .fill(prospect.category.accentColor)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: prospect.category.icon)
                                        .font(.caption2)
                                        .foregroundStyle(.white)
                                )
                                .shadow(color: prospect.category.accentColor.opacity(0.4), radius: 4)
                            Text(prospect.name)
                                .font(.caption2.bold())
                                .lineLimit(1)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .frame(height: 300)
        .overlay(alignment: .top) {
            if appState.discovery.isSearching {
                Label("Searching \(selectedCategory.rawValue.lowercased())...", systemImage: "sparkle.magnifyingglass")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.top, 10)
            }
        }
    }

    private var resultsSection: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack {
                    Text("\(appState.discovery.results.count) companies found")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                    Spacer()
                    if let remaining = appState.subscription.usage.discoverySearchesRemaining {
                        Text("\(remaining) searches left")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }

                if let error = appState.discovery.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(AppTheme.dangerRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if appState.discovery.results.isEmpty && !appState.discovery.isSearching && hasSearched {
                    EmptyStateView(
                        icon: "building.2",
                        title: "No companies found",
                        message: "Try another category, widen the radius, or search a specific company name."
                    )
                } else {
                    ForEach(appState.discovery.results) { prospect in
                        Button {
                            selectedProspect = prospect
                        } label: {
                            ProspectRow(prospect: prospect)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
    }

    private func lockLocationAndSearch() async {
        guard let coordinate = await appState.location.ensureCurrentLocation() else { return }
        centerMap(on: coordinate)
        await runSearch()
    }

    private func runSearch() async {
        guard appState.subscription.canSearchProspects() else {
            appState.discovery.errorMessage = "Monthly search limit reached. Upgrade for more."
            return
        }

        guard let coordinate = await appState.location.ensureCurrentLocation() else { return }

        await appState.discovery.search(
            category: selectedCategory,
            companyQuery: companySearch,
            near: coordinate,
            radius: selectedRadius
        )
        appState.subscription.recordDiscoverySearch()
        hasSearched = true
        centerMap(on: coordinate)
    }

    private func centerMap(on coordinate: CLLocationCoordinate2D) {
        let delta = selectedRadius.meters / 111_000 * 1.2
        cameraPosition = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
            )
        )
    }
}

struct ProspectRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let prospect: DiscoveredProspect

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(prospect.category.accentColor.opacity(0.18))
                    .frame(width: 48, height: 48)
                Image(systemName: prospect.category.icon)
                    .foregroundStyle(prospect.category.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(prospect.name)
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                Text([prospect.address, prospect.city].filter { !$0.isEmpty }.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text(prospect.category.rawValue)
                        .font(.caption2.bold())
                        .foregroundStyle(prospect.category.accentColor)
                    if let distance = prospect.distanceLabel {
                        Text(distance)
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }
            }

            Spacer()

            VStack(spacing: 4) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.tealGreen)
                Text("Add")
                    .font(.caption2.bold())
                    .foregroundStyle(AppTheme.tealGreen)
            }
        }
        .padding(14)
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.borderColor(for: colorScheme), lineWidth: 1)
        )
    }
}

struct ProspectLockSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let prospect: DiscoveredProspect
    let onLock: (Lead) -> Void

    @State private var contactName = ""
    @State private var notes = ""
    @State private var contactIntel = ContactIntel()
    @State private var enableProximityAlert = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: prospect.category.icon)
                            .foregroundStyle(prospect.category.accentColor)
                            .frame(width: 36, height: 36)
                            .background(prospect.category.accentColor.opacity(0.15))
                            .clipShape(Circle())
                        VStack(alignment: .leading) {
                            Text(prospect.name).font(.headline)
                            Text(prospect.category.rawValue).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Business Details") {
                    LabeledContent("Address", value: prospect.address)
                    if !prospect.city.isEmpty {
                        LabeledContent("City", value: prospect.city)
                    }
                    if let phone = prospect.phone {
                        LabeledContent("Phone", value: phone)
                    }
                    if let website = prospect.website {
                        LabeledContent("Website", value: website)
                    }
                    if let distance = prospect.distanceLabel {
                        LabeledContent("Distance", value: distance)
                    }
                }

                Section("CRM Details") {
                    TextField("Contact name", text: $contactName)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Personal Details") {
                    TextField("What they like", text: $contactIntel.likes)
                    TextField("Interests & hobbies", text: $contactIntel.interests)
                    TextField("Kids' names", text: $contactIntel.kidsNames)
                    TextField("Family notes", text: $contactIntel.familyNotes)
                    TextField("Conversation starters", text: $contactIntel.conversationStarters, axis: .vertical)
                        .lineLimit(2...3)
                }

                Section("Proximity Alerts") {
                    Toggle("Alert me with contact facts when I'm nearby", isOn: $enableProximityAlert)
                }
            }
            .navigationTitle("Add to CRM")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Client") { addProspect() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func addProspect() {
        guard let userId = appState.auth.currentUser?.id else { return }

        let location = LeadLocation(
            address: prospect.address,
            city: prospect.city,
            latitude: prospect.latitude,
            longitude: prospect.longitude,
            locationLabel: prospect.name,
            pinReminderEnabled: enableProximityAlert
        )

        let lead = Lead(
            ownerId: userId,
            name: contactName.isEmpty ? "Contact at \(prospect.name)" : contactName,
            company: prospect.name,
            phone: prospect.phone ?? "",
            notes: notes,
            leadSource: prospect.category.rawValue,
            contactIntel: contactIntel,
            location: location,
            activities: [
                LeadActivity(type: .visit, summary: "Added from map discovery (\(prospect.category.rawValue))")
            ]
        )

        onLock(lead)
        dismiss()
    }
}
