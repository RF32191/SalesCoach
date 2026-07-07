import SwiftUI

struct TutorialLibraryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    @State private var selectedTutorial: AppTutorial?

    private var filteredCategories: [String] {
        let categories = AppTutorialCatalog.categories
        guard !searchText.isEmpty else { return categories }
        return categories.filter { category in
            AppTutorialCatalog.tutorials(in: category).contains { tutorial in
                tutorial.title.localizedCaseInsensitiveContains(searchText) ||
                tutorial.summary.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                libraryHero
                searchBar

                ForEach(filteredCategories, id: \.self) { category in
                    categorySection(category)
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Tutorial Library")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .sheet(item: $selectedTutorial) { tutorial in
            NavigationStack {
                TutorialDetailView(tutorial: tutorial)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { selectedTutorial = nil }
                        }
                    }
            }
        }
    }

    private var libraryHero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Tutorial Library", systemImage: "graduationcap.fill")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.tealGreen)
            Text("Learn every screen in Sales Coach AI")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            Text("\(AppTutorialCatalog.all.count) tutorials covering tabs, CRM, coaching, platform modules, and settings.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(AppTheme.textMuted)
            TextField("Search tutorials...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(12)
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func categorySection(_ category: String) -> some View {
        let tutorials = AppTutorialCatalog.tutorials(in: category).filter { tutorial in
            searchText.isEmpty ||
            tutorial.title.localizedCaseInsensitiveContains(searchText) ||
            tutorial.summary.localizedCaseInsensitiveContains(searchText)
        }
        if !tutorials.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: category)
                ForEach(tutorials) { tutorial in
                    Button {
                        selectedTutorial = tutorial
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: tutorial.icon)
                                .font(.title3)
                                .foregroundStyle(tutorial.accent)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(tutorial.title).font(.subheadline.bold())
                                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                                    .multilineTextAlignment(.leading)
                                Text(tutorial.summary).font(.caption)
                                    .foregroundStyle(AppTheme.textMuted)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Image(systemName: "book.fill")
                                .font(.caption)
                                .foregroundStyle(AppTheme.tealGreen)
                        }
                        .cardStyle()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct TutorialDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    let tutorial: AppTutorial

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    Image(systemName: tutorial.icon)
                        .font(.largeTitle)
                        .foregroundStyle(tutorial.accent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tutorial.title).font(.title2.bold())
                        Text(tutorial.category).font(.caption.bold()).foregroundStyle(AppTheme.textMuted)
                    }
                }

                Text(tutorial.summary)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))

                Label(tutorial.whereToFind, systemImage: "arrow.turn.up.right")
                    .font(.caption.bold())
                    .foregroundStyle(tutorial.accent)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(tutorial.accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                SectionHeader(title: "How To Use")
                ForEach(Array(tutorial.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(tutorial.accent)
                            .clipShape(Circle())
                        Text(step)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if !tutorial.proTips.isEmpty {
                    SectionHeader(title: "Pro Tips")
                    ForEach(tutorial.proTips, id: \.self) { tip in
                        Label(tip, systemImage: "lightbulb.fill")
                            .font(.caption)
                            .foregroundStyle(AppTheme.warningOrange)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(AppTheme.warningOrange.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Tutorial")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TutorialHelpButton: View {
    let tutorialID: AppTutorialID
    @State private var showTutorial = false

    var body: some View {
        Button {
            showTutorial = true
        } label: {
            Image(systemName: "questionmark.circle")
                .foregroundStyle(AppTheme.tealGreen)
        }
        .accessibilityLabel("Tutorial for this screen")
        .sheet(isPresented: $showTutorial) {
            NavigationStack {
                TutorialDetailView(tutorial: AppTutorialCatalog.tutorial(for: tutorialID))
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showTutorial = false }
                        }
                    }
            }
        }
    }
}
