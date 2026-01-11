import SwiftUI

struct FloatingPanelContent: View {
    @Environment(AppState.self) private var appState
    @State private var selectedIndex = 0
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        @Bindable var appState = appState

        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.title2)

                TextField("Search links...", text: $appState.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.title2)
                    .focused($isSearchFocused)
                    .onSubmit {
                        openSelectedLink()
                    }

                if !appState.searchQuery.isEmpty {
                    Button {
                        appState.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(.ultraThinMaterial)

            Divider()

            // Results list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(appState.filteredLinks.enumerated()), id: \.element.id) { index, link in
                            LinkRow(
                                link: link,
                                category: categoryName(for: link),
                                isSelected: index == selectedIndex
                            )
                            .onTapGesture {
                                selectedIndex = index
                                openSelectedLink()
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onChange(of: selectedIndex) { _, newValue in
                    let links = appState.filteredLinks
                    guard newValue < links.count else { return }
                    withAnimation {
                        proxy.scrollTo(links[newValue].id, anchor: .center)
                    }
                }
            }
            .background(.regularMaterial)
        }
        .frame(width: 600, height: 400)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.quaternary, lineWidth: 1)
        )
        .onAppear {
            isSearchFocused = true
            selectedIndex = 0
        }
        .onChange(of: appState.searchQuery) { _, _ in
            selectedIndex = 0
        }
        .onKeyPress(.upArrow) {
            moveSelection(by: -1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveSelection(by: 1)
            return .handled
        }
        .onKeyPress(.escape) {
            appState.dismissPanel()
            return .handled
        }
    }

    private func moveSelection(by delta: Int) {
        let count = appState.filteredLinks.count
        guard count > 0 else { return }

        selectedIndex = (selectedIndex + delta + count) % count
    }

    private func openSelectedLink() {
        let links = appState.filteredLinks
        guard selectedIndex < links.count else { return }
        appState.openLink(links[selectedIndex])
    }

    private func categoryName(for link: Link) -> String? {
        guard let config = appState.config else { return nil }
        return config.categories.first { $0.links.contains(where: { $0.id == link.id }) }?.name
    }
}

struct LinkRow: View {
    let link: Link
    let category: String?
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(link.name)
                    .font(.body)
                    .fontWeight(isSelected ? .medium : .regular)

                if let category = category {
                    Text(category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(link.url)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .contentShape(Rectangle())
    }
}
