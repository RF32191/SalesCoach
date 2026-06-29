import SwiftUI

struct ScoreRing: View {
    let score: Int
    var size: CGFloat = 120
    var lineWidth: CGFloat = 10

    private var progress: Double {
        Double(score) / 100.0
    }

    private var scoreColor: Color {
        if score >= 80 { return AppTheme.successGreen }
        if score >= 60 { return AppTheme.electricBlue }
        if score >= 40 { return AppTheme.warningOrange }
        return AppTheme.dangerRed
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.navyElevated, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(scoreColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: score)

            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: size * 0.28, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("/ 100")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(width: size, height: size)
    }
}

struct CategoryScoreBar: View {
    let category: ScoreCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(category.name)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text("\(category.score)")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.electricBlue)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.navyElevated)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.electricBlue)
                        .frame(width: geo.size.width * CGFloat(category.score) / 100)
                }
            }
            .frame(height: 6)
        }
    }
}

struct ReportSection: View {
    let title: String
    let icon: String
    let items: [String]
    var iconColor: Color = AppTheme.electricBlue

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
            }

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(iconColor)
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    Text(item)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .cardStyle()
    }
}
