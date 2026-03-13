import SwiftUI
import SwiftData

private enum AppTab: Equatable {
    case artifacts, newArtifact, backup
}

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"

    @AppStorage("accent") private var accentRaw: String = AccentChoice.blue.rawValue

    @State private var sidebarSelection: SidebarSelection = .all
    @State private var searchText = ""
    @State private var showExportImport = false  // iPad / macOS only
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    private var preferredScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    private var accentColor: Color {
        AccentChoice.from(raw: accentRaw).color
    }

    var body: some View {
        #if os(macOS)
        splitLayout
            .preferredColorScheme(preferredScheme)
        #else
        Group {
            if UIDevice.current.userInterfaceIdiom == .phone {
                iPhoneLayout
            } else {
                splitLayout
            }
        }
        .preferredColorScheme(preferredScheme)
        #endif
    }

    // MARK: - iPhone layout
    //
    // Architecture: Artifacts tab lives in a persistent NavigationStack so its
    // drill-down state is preserved across tab switches. New Artifact and Backup
    // are ZStack overlays. All three transitions use identical opacity crossfades —
    // consistent, non-spatial, appropriate for sibling-level navigation.
    // Directional push/pop is reserved for hierarchy (drill-down within Artifacts).

    #if os(iOS)
    @State private var activeTab: AppTab = .artifacts
    @State private var navigationPath: [SidebarSelection] = []

    private var iPhoneLayout: some View {
        ZStack {
            // Artifacts — always alive, opacity-toggled to preserve nav state
            NavigationStack(path: $navigationPath) {
                SidebarView(
                    selection: $sidebarSelection,
                    onSelect: { navigationPath = [sidebarSelection] },
                    onSearchActivate: {
                        navigationPath = [SidebarSelection.all]
                    },
                    onBackupTapped: {}
                )
                .navigationDestination(for: SidebarSelection.self) { filter in
                    EntriesListView(filter: filter, searchText: searchText)
                        .searchable(
                            text: $searchText,
                            placement: .navigationBarDrawer(displayMode: .always),
                            prompt: "Search artifacts…"
                        )
                }
            }
            .onChange(of: navigationPath) { _, path in
                if path.isEmpty { searchText = "" }
            }
            .opacity(activeTab == .artifacts ? 1 : 0)
            .allowsHitTesting(activeTab == .artifacts)

            // New Artifact — crossfades in/out
            if activeTab == .newArtifact {
                EntryFormView(entry: nil, onComplete: {
                    withAnimation(.easeInOut(duration: 0.22)) { activeTab = .artifacts }
                })
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .ignoresSafeArea()
                .zIndex(1)
            }

            // Backup — crossfades in/out
            if activeTab == .backup {
                ExportImportView(onComplete: {
                    withAnimation(.easeInOut(duration: 0.22)) { activeTab = .artifacts }
                })
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: activeTab)
        .tint(accentColor)
        .safeAreaInset(edge: .bottom) {
            if activeTab != .newArtifact { bottomNav }
        }
    }

    private var bottomNav: some View {
        HStack(spacing: 0) {
            bottomNavItem(
                activeIcon: "line.3.horizontal",
                inactiveIcon: "line.3.horizontal",
                label: "Artifacts",
                tab: .artifacts
            ) {
                if activeTab == .artifacts {
                    navigationPath = []         // tap active tab → pop to root
                } else {
                    withAnimation(.easeInOut(duration: 0.22)) { activeTab = .artifacts }
                }
            }
            bottomNavItem(
                activeIcon: "plus.circle.fill",
                inactiveIcon: "plus.circle",
                label: "New Artifact",
                tab: .newArtifact
            ) {
                withAnimation(.easeInOut(duration: 0.22)) { activeTab = .newArtifact }
            }
            bottomNavItem(
                activeIcon: "ellipsis.circle.fill",
                inactiveIcon: "ellipsis.circle",
                label: "More",
                tab: .backup
            ) {
                withAnimation(.easeInOut(duration: 0.22)) { activeTab = .backup }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(Color(.systemGray6))
        .overlay(alignment: .top) { Divider() }
    }

    private func bottomNavItem(
        activeIcon: String,
        inactiveIcon: String,
        label: String,
        tab: AppTab,
        action: @escaping () -> Void
    ) -> some View {
        let isActive = activeTab == tab
        return Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isActive ? activeIcon : inactiveIcon)
                    .font(.title3)
                Text(label)
                    .font(.caption2)
                    .fontWeight(isActive ? .medium : .regular)
            }
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(isActive ? accentColor : Color.primary.opacity(0.45))
    }
    #endif

    // MARK: - iPad / macOS layout

    private var splitLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(
                selection: $sidebarSelection,
                onBackupTapped: { showExportImport = true }
            )
        } detail: {
            EntriesListView(filter: sidebarSelection, searchText: searchText)
                #if os(iOS)
                .searchable(
                    text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search artifacts…"
                )
                #else
                .searchable(text: $searchText, prompt: "Search artifacts…")
                #endif
        }
        .toolbar(removing: .sidebarToggle)
        .sheet(isPresented: $showExportImport) {
            ExportImportView()
                #if os(iOS)
                .presentationDetents([.large])
                #endif
        }
        .tint(accentColor)
    }
}

// MARK: - Sidebar Selection

enum SidebarSelection: Hashable, Equatable {
    case all
    case favorites
    case category(String)
}
