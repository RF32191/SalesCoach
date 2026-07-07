import SwiftUI

struct LeadContactLinkRow: View {
    let lead: Lead
    var onCall: (() -> Void)? = nil
    var onEmail: (() -> Void)? = nil
    var onText: (() -> Void)? = nil
    var compact: Bool = false

    var body: some View {
        if lead.phone.isEmpty && lead.email.isEmpty {
            EmptyView()
        } else {
            HStack(spacing: compact ? 8 : 10) {
                if !lead.phone.isEmpty {
                    ContactLinkChip(
                        title: compact ? "Call" : lead.phone,
                        icon: "phone.fill",
                        color: AppTheme.successGreen,
                        action: { onCall?() ?? LeadCommunicationService.call(lead: lead) }
                    )
                    if !compact {
                        ContactLinkChip(
                            title: "Text",
                            icon: "message.fill",
                            color: AppTheme.tealGreen,
                            action: { onText?() ?? LeadCommunicationService.text(lead: lead) }
                        )
                    }
                }
                if !lead.email.isEmpty {
                    ContactLinkChip(
                        title: compact ? "Email" : truncatedEmail,
                        icon: "envelope.fill",
                        color: AppTheme.electricBlueBright,
                        action: { onEmail?() ?? LeadCommunicationService.email(lead: lead) }
                    )
                }
            }
        }
    }

    private var truncatedEmail: String {
        if lead.email.count <= 24 { return lead.email }
        return String(lead.email.prefix(21)) + "..."
    }
}

struct ContactLinkChip: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
                .foregroundStyle(color)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

struct LeadContactInfoRows: View {
    let lead: Lead
    var onCall: (() -> Void)? = nil
    var onEmail: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 10) {
            if !lead.phone.isEmpty {
                tappableRow(label: "Phone", value: lead.phone, icon: "phone.fill", color: AppTheme.successGreen) {
                    onCall?() ?? LeadCommunicationService.call(lead: lead)
                }
            }
            if !lead.email.isEmpty {
                tappableRow(label: "Email", value: lead.email, icon: "envelope.fill", color: AppTheme.electricBlueBright) {
                    onEmail?() ?? LeadCommunicationService.email(lead: lead)
                }
            }
        }
    }

    private func tappableRow(label: String, value: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(label, systemImage: icon)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundStyle(color)
                    .lineLimit(1)
                Image(systemName: "arrow.up.right")
                    .font(.caption2.bold())
                    .foregroundStyle(color.opacity(0.7))
            }
        }
        .buttonStyle(.plain)
    }
}
