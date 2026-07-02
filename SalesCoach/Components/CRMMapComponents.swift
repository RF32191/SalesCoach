import MapKit
import SwiftUI

struct MapLegendChip: View {
    let color: Color
    let label: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Image(systemName: icon)
                .font(.caption2)
            Text(label)
                .font(.caption2.bold())
        }
        .foregroundStyle(.white.opacity(0.92))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

struct ClientMapPin: View {
    let title: String
    let isProximityEnabled: Bool
    let accent: Color

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.25))
                    .frame(width: 44, height: 44)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accent, accent.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 34, height: 34)
                    .shadow(color: accent.opacity(0.45), radius: 6, y: 3)
                Image(systemName: isProximityEnabled ? "bell.fill" : "person.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
            Text(title)
                .font(.caption2.bold())
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        }
    }
}

struct ProspectMapPin: View {
    let title: String
    let category: SalesCategory

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(category.accentColor.opacity(0.35), lineWidth: 2)
                    .frame(width: 40, height: 40)
                Circle()
                    .fill(category.accentColor)
                    .frame(width: 30, height: 30)
                Image(systemName: category.icon)
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
            }
            Text(title)
                .font(.caption2.bold())
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(category.accentColor.opacity(0.18))
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        }
    }
}

struct GlassMapToolbar: View {
    @Environment(\.colorScheme) private var colorScheme
    let items: [(icon: String, label: String, value: String, color: Color)]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 2) {
                    Label(item.label, systemImage: item.icon)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    Text(item.value)
                        .font(.caption.bold())
                        .foregroundStyle(item.color)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(AppTheme.cardBackground(for: colorScheme).opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

struct RouteStopCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let stop: RouteStop
    var etaLabel: String? = nil
    var origin: CLLocationCoordinate2D? = nil
    var isLast: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(AppTheme.tealGreen.opacity(0.18))
                        .frame(width: 36, height: 36)
                    Text("\(stop.order)")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.tealGreen)
                }
                if !isLast {
                    Rectangle()
                        .fill(AppTheme.tealGreen.opacity(0.25))
                        .frame(width: 2, height: 28)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(stop.lead.company.isEmpty ? stop.lead.name : stop.lead.company)
                            .font(.headline)
                            .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                        Text(stop.lead.name)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("$\(Int(stop.lead.dealValue))")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.successGreen)
                        if let etaLabel {
                            Label(etaLabel, systemImage: "car.fill")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.electricBlueBright)
                        } else if let distance = stop.distanceLabel {
                            Text(distance)
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textMuted)
                        }
                    }
                }

                Text(stop.lead.aiRecommendedAction)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                    .lineLimit(2)

                HStack(spacing: 8) {
                    StageBadge(stage: stop.lead.dealStage)
                    PriorityBadge(priority: stop.lead.priority)
                    Spacer()
                    NavigationLink {
                        LeadDetailView(lead: stop.lead)
                    } label: {
                        Label("Open", systemImage: "arrow.up.right")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.electricBlueBright)
                    }
                }

                if stop.lead.location.hasCoordinates,
                   let latitude = stop.lead.location.latitude,
                   let longitude = stop.lead.location.longitude {
                    AppleMapsNavigateButton(
                        title: "Navigate",
                        name: stop.lead.company.isEmpty ? stop.lead.name : stop.lead.company,
                        latitude: latitude,
                        longitude: longitude,
                        origin: origin,
                        style: .compact
                    )
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardBackground(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.borderColor(for: colorScheme), lineWidth: 1)
            )
        }
    }
}
