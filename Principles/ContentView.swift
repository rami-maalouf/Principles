//
//  ContentView.swift
//  Principles
//
//  Created by Codex on 2026-03-10.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: RootTab = .tracker

    var body: some View {
        TabView(selection: $selectedTab) {
            TrackerHomeScreen()
                .tabItem {
                    Label("Principles", systemImage: "sparkles.rectangle.stack")
                }
                .tag(RootTab.tracker)

            ArchiveScreen()
                .tabItem {
                    Label("Archive", systemImage: "archivebox")
                }
                .tag(RootTab.archive)

            SettingsScreen()
                .tabItem {
                    Label("Settings", systemImage: "paintpalette")
                }
                .tag(RootTab.settings)
        }
        .tint(themeStore.palette(for: colorScheme).accent)
    }
}

private enum RootTab: Hashable {
    case tracker
    case archive
    case settings
}

private struct TrackerHomeScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeStore: ThemeStore
    @Query(sort: \Principle.updatedAt, order: .reverse) private var principles: [Principle]

    @State private var isPresentingComposer = false

    private var palette: ThemePalette {
        themeStore.palette(for: colorScheme)
    }

    private var activePrinciples: [Principle] {
        principles
            .filter { !$0.isArchived }
            .sorted {
                let left = $0.analytics().currentStreak
                let right = $1.analytics().currentStreak

                if left == right {
                    return $0.updatedAt > $1.updatedAt
                }

                return left > right
            }
    }

    private var timelineDates: [Date] {
        PrincipleAnalytics.timelineDates(count: themeStore.visibleHistoryDays)
    }

    private var completedTodayCount: Int {
        activePrinciples.filter { $0.analytics().completedToday }.count
    }

    private var bestCurrentStreak: Int {
        activePrinciples.map { $0.analytics().currentStreak }.max() ?? 0
    }

    private var graduatedCount: Int {
        principles.filter { $0.hasGraduated || $0.analytics().hasGraduated }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphereBackground(palette: palette)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        heroCard

                        if activePrinciples.isEmpty {
                            emptyState
                        } else {
                            trackerCard
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Principles")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingComposer = true
                    } label: {
                        Label("New Principle", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingComposer) {
                PrincipleComposerView()
                    .environmentObject(themeStore)
            }
            .navigationDestination(for: Principle.self) { principle in
                PrincipleDetailView(principle: principle)
                    .environmentObject(themeStore)
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Make each principle real for 21 straight days.")
                        .font(.system(size: 31, weight: .semibold, design: .serif))
                        .foregroundStyle(palette.textPrimary)

                    Text("Each check-in moves a belief from intention to identity. When it survives 21 days in a row, it graduates into the archive.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 20)

                ZStack {
                    Circle()
                        .fill(palette.accentSoft)
                        .frame(width: 82, height: 82)
                        .blur(radius: 0.2)

                    Circle()
                        .stroke(palette.accent.opacity(0.35), lineWidth: 1.5)
                        .frame(width: 92, height: 92)

                    VStack(spacing: 3) {
                        Text("\(bestCurrentStreak)")
                            .font(.system(size: 30, weight: .bold, design: .monospaced))
                            .foregroundStyle(palette.textPrimary)
                            .monospacedDigit()

                        Text("best")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(palette.textMuted)
                            .textCase(.uppercase)
                    }
                }
                .shadow(color: palette.accentGlow.opacity(0.28), radius: 22, y: 8)
            }

            HStack(spacing: 12) {
                SummaryChip(
                    title: "Active",
                    value: "\(activePrinciples.count)",
                    icon: "circle.grid.2x2.fill",
                    palette: palette
                )
                SummaryChip(
                    title: "Today",
                    value: "\(completedTodayCount)",
                    icon: "checkmark.seal.fill",
                    palette: palette
                )
                SummaryChip(
                    title: "Graduated",
                    value: "\(graduatedCount)",
                    icon: "archivebox.fill",
                    palette: palette
                )
            }
        }
        .principlePanel(palette, glow: true)
    }

    private var trackerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Ledger")
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                        .foregroundStyle(palette.textPrimary)

                    Text("The most recent date stays on the far right, just like Loop.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(palette.textMuted)
                }

                Spacer()

                Text("\(themeStore.visibleHistoryDays) days")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(palette.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(palette.accentSoft)
                    )
            }

            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    TrackerHeaderRow(
                        dates: timelineDates,
                        palette: palette
                    )

                    ForEach(activePrinciples) { principle in
                        PrincipleTrackerRow(
                            principle: principle,
                            dates: timelineDates,
                            palette: palette,
                            onToggleToday: {
                                toggleToday(for: principle)
                            }
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .principlePanel(palette)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No principles yet", systemImage: "sparkles")
                .foregroundStyle(palette.textPrimary)
        } description: {
            Text("Start with one principle you want to embody daily. The home screen will become your streak board.")
                .foregroundStyle(palette.textSecondary)
        } actions: {
            Button("Create your first principle") {
                isPresentingComposer = true
            }
            .buttonStyle(.borderedProminent)
            .tint(palette.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .principlePanel(palette)
    }

    private func toggleToday(for principle: Principle) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.84)) {
            toggleCheckIn(for: principle, using: modelContext)
        }
    }
}

private struct ArchiveScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeStore: ThemeStore
    @Query(sort: \Principle.archivedAt, order: .reverse) private var principles: [Principle]

    private var palette: ThemePalette {
        themeStore.palette(for: colorScheme)
    }

    private var archivedPrinciples: [Principle] {
        principles.filter(\.isArchived)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphereBackground(palette: palette)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        archiveHero

                        if archivedPrinciples.isEmpty {
                            ContentUnavailableView {
                                Label("Archive is empty", systemImage: "archivebox")
                                    .foregroundStyle(palette.textPrimary)
                            } description: {
                                Text("Graduated principles will land here automatically, and you can restore them whenever you want.")
                                    .foregroundStyle(palette.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .principlePanel(palette)
                        } else {
                            LazyVStack(spacing: 14) {
                                ForEach(archivedPrinciples) { principle in
                                    ArchiveCard(
                                        principle: principle,
                                        palette: palette,
                                        onRestore: {
                                            restore(principle)
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Archive")
            .navigationDestination(for: Principle.self) { principle in
                PrincipleDetailView(principle: principle)
                    .environmentObject(themeStore)
            }
        }
    }

    private var archiveHero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Graduated principles keep their history.")
                .font(.system(size: 29, weight: .semibold, design: .serif))
                .foregroundStyle(palette.textPrimary)

            Text("Restoring a principle brings it back to the active board without losing streaks, totals, or its graduation date.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(palette.textSecondary)

            HStack(spacing: 12) {
                SummaryChip(
                    title: "Archived",
                    value: "\(archivedPrinciples.count)",
                    icon: "archivebox.fill",
                    palette: palette
                )
                SummaryChip(
                    title: "Restorable",
                    value: archivedPrinciples.isEmpty ? "0" : "Yes",
                    icon: "arrow.uturn.left.circle.fill",
                    palette: palette
                )
            }
        }
        .principlePanel(palette)
    }

    private func restore(_ principle: Principle) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
            principle.archivedAt = nil
            principle.updatedAt = .now
            try? modelContext.save()
        }
    }
}

private struct SettingsScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeStore: ThemeStore

    private var livePalette: ThemePalette {
        themeStore.palette(for: colorScheme)
    }

    private var previewScheme: ColorScheme {
        themeStore.preferredColorScheme ?? colorScheme
    }

    private var previewPalette: ThemePalette {
        themeStore.palette(for: previewScheme)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphereBackground(palette: livePalette)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        previewCard
                        appearanceCard
                        accentCard(
                            title: "Dark Accent",
                            scheme: .dark,
                            selection: $themeStore.darkAccent
                        )
                        accentCard(
                            title: "Light Accent",
                            scheme: .light,
                            selection: $themeStore.lightAccent
                        )
                        trackerSettingsCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Live Preview")
                .font(.system(size: 24, weight: .semibold, design: .serif))
                .foregroundStyle(livePalette.textPrimary)

            Text("Adjust the theme and accent colors until the tracker feels like your own private operating system.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(livePalette.textSecondary)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    TodayOrb(
                        isCompleted: true,
                        palette: previewPalette
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tell the truth early")
                            .font(.system(size: 20, weight: .semibold, design: .serif))
                            .foregroundStyle(previewPalette.textPrimary)

                        Text("12 day streak")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(previewPalette.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(previewPalette.accentSoft)
                            )
                    }

                    Spacer()
                }

                HStack(spacing: 6) {
                    ForEach(samplePreviewStates) { state in
                        TrackerDayCell(
                            state: state,
                            palette: previewPalette
                        )
                    }
                }
            }
            .principlePanel(previewPalette, glow: true)
        }
        .principlePanel(livePalette)
    }

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Appearance")
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(livePalette.textPrimary)

            Picker("Appearance", selection: $themeStore.appearance) {
                ForEach(AppAppearancePreference.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text("Default is dark, but you can lock the app to light or follow the device.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(livePalette.textMuted)
        }
        .principlePanel(livePalette)
    }

    private func accentCard(
        title: String,
        scheme: ColorScheme,
        selection: Binding<AccentPalette>
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(livePalette.textPrimary)

            Text("Pick the accent that should drive the \(scheme == .dark ? "dark" : "light") theme.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(livePalette.textMuted)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 88), spacing: 12)],
                spacing: 12
            ) {
                ForEach(AccentPalette.allCases) { accent in
                    AccentSwatch(
                        accent: accent,
                        scheme: scheme,
                        isSelected: selection.wrappedValue == accent,
                        palette: livePalette
                    ) {
                        selection.wrappedValue = accent
                    }
                }
            }
        }
        .principlePanel(livePalette)
    }

    private var trackerSettingsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tracker Strip")
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(livePalette.textPrimary)

            Picker("Visible days", selection: $themeStore.visibleHistoryDays) {
                ForEach(themeStore.historyOptions, id: \.self) { days in
                    Text("\(days) days").tag(days)
                }
            }
            .pickerStyle(.segmented)

            Text("Choose how much recent history appears on the home matrix.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(livePalette.textMuted)
        }
        .principlePanel(livePalette)
    }

    private var samplePreviewStates: [PrincipleDayState] {
        let dates = PrincipleAnalytics.timelineDates(count: 14)
        return dates.enumerated().map { index, date in
            PrincipleDayState(
                id: date,
                date: date,
                isCompleted: [1, 2, 4, 5, 6, 8, 9, 10, 12, 13].contains(index),
                isToday: index == 13
            )
        }
    }
}

private struct PrincipleDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeStore: ThemeStore
    @Bindable var principle: Principle

    private var palette: ThemePalette {
        themeStore.palette(for: colorScheme)
    }

    private var stats: PrincipleAnalyticsSnapshot {
        principle.analytics()
    }

    private var titleBinding: Binding<String> {
        Binding(
            get: { principle.title },
            set: {
                principle.title = $0
                principle.updatedAt = .now
            }
        )
    }

    private var descriptionBinding: Binding<String> {
        Binding(
            get: { principle.principleDescription },
            set: {
                principle.principleDescription = $0
                principle.updatedAt = .now
            }
        )
    }

    var body: some View {
        ZStack {
            AtmosphereBackground(palette: palette)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    detailHero
                    metricsGrid
                    identityCard
                    historyCard
                    actionCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(principle.title)
    }

    private var detailHero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 18) {
                ProgressRing(
                    progress: stats.progressFraction,
                    label: stats.hasGraduated ? "Done" : "\(stats.remainingToGraduate) left",
                    value: stats.hasGraduated ? principle.targetDays : stats.currentStreak,
                    palette: palette
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text(principle.hasGraduated || stats.hasGraduated ? "Graduated Principle" : "In Active Rotation")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(palette.accent)
                        .textCase(.uppercase)

                    Text(principle.title)
                        .font(.system(size: 31, weight: .semibold, design: .serif))
                        .foregroundStyle(palette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(statusCopy)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                    toggleCheckIn(for: principle, using: modelContext)
                }
            } label: {
                HStack {
                    Image(systemName: stats.completedToday ? "checkmark.circle.fill" : "circle")
                    Text(stats.completedToday ? "Marked for today" : "Mark today")
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(stats.completedToday ? palette.accentSoft : palette.accent)
                )
                .foregroundStyle(stats.completedToday ? palette.textPrimary : Color.black.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .principlePanel(palette, glow: true)
    }

    private var metricsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            MetricTile(
                title: "Current streak",
                value: "\(stats.currentStreak)",
                detail: "days in a row",
                palette: palette
            )
            MetricTile(
                title: "Longest streak",
                value: "\(stats.longestStreak)",
                detail: "best run",
                palette: palette
            )
            MetricTile(
                title: "Completion",
                value: "\(Int((stats.completionRate * 100).rounded()))%",
                detail: "\(stats.totalCheckIns) of \(stats.activeDayCount) days",
                palette: palette
            )
            MetricTile(
                title: "Last check-in",
                value: detailDate(stats.lastCheckIn),
                detail: principle.graduatedAt != nil ? "graduated \(detailDate(principle.graduatedAt))" : "keep it alive",
                palette: palette
            )
        }
    }

    private var identityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Identity")
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(palette.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(palette.textMuted)
                    .textCase(.uppercase)

                TextField("Name this principle", text: titleBinding)
                    .textFieldStyle(.plain)
                    .font(.system(size: 21, weight: .semibold, design: .serif))
                    .foregroundStyle(palette.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(palette.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(palette.border, lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Reason")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(palette.textMuted)
                    .textCase(.uppercase)

                TextEditor(text: descriptionBinding)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 150)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(palette.textPrimary)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(palette.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(palette.border, lineWidth: 1)
                    )
            }
        }
        .principlePanel(palette)
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent History")
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(palette.textPrimary)

            Text("A 42-day snapshot makes it obvious whether this principle is becoming a pattern or just a mood.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(palette.textSecondary)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7),
                spacing: 8
            ) {
                ForEach(PrincipleAnalytics.timelineState(
                    checkIns: principle.checkIns.map(\.day),
                    count: 42
                )) { state in
                    VStack(spacing: 6) {
                        TrackerDayCell(
                            state: state,
                            palette: palette,
                            size: 22
                        )

                        Text(state.date.formatted(.dateTime.day()))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(state.isToday ? palette.accent : palette.textMuted)
                    }
                }
            }
        }
        .principlePanel(palette)
    }

    private var actionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("State")
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(palette.textPrimary)

            Text(principle.isArchived
                 ? "This principle is currently in the archive, but all of its history remains intact."
                 : "Archiving removes the principle from the active board without erasing any data.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(palette.textSecondary)

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                    if principle.isArchived {
                        principle.archivedAt = nil
                    } else {
                        principle.archivedAt = .now
                    }
                    principle.updatedAt = .now
                    try? modelContext.save()
                }
            } label: {
                HStack {
                    Image(systemName: principle.isArchived ? "arrow.uturn.left.circle.fill" : "archivebox.fill")
                    Text(principle.isArchived ? "Restore to active" : "Move to archive")
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(palette.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(palette.border, lineWidth: 1)
                )
                .foregroundStyle(palette.textPrimary)
            }
            .buttonStyle(.plain)
        }
        .principlePanel(palette)
    }

    private var statusCopy: String {
        if let graduatedAt = principle.graduatedAt {
            return "Graduated on \(detailDate(graduatedAt)) and preserved in your archive."
        }

        if stats.completedToday {
            return "\(stats.currentStreak) consecutive days alive. Keep the line unbroken."
        }

        if stats.completedYesterday {
            return "You can protect the streak today and move \(stats.remainingToGraduate) days closer to graduation."
        }

        return "The streak is cold right now. Today can still become the new day one."
    }

    private func detailDate(_ date: Date?) -> String {
        guard let date else {
            return "No data"
        }

        return date.formatted(.dateTime.month(.abbreviated).day())
    }
}

private struct PrincipleComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeStore: ThemeStore

    @State private var title = ""
    @State private var description = ""
    @State private var markToday = true

    private var palette: ThemePalette {
        themeStore.palette(for: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphereBackground(palette: palette)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Create a principle worth repeating.")
                                .font(.system(size: 30, weight: .semibold, design: .serif))
                                .foregroundStyle(palette.textPrimary)

                            Text("Give it a clear title and capture the reason behind it. The title appears on the home screen; the reasoning lives with it forever.")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(palette.textSecondary)
                        }
                        .principlePanel(palette)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Title")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(palette.textMuted)
                                .textCase(.uppercase)

                            TextField("Example: Tell the truth early", text: $title)
                                .textFieldStyle(.plain)
                                .font(.system(size: 22, weight: .semibold, design: .serif))
                                .foregroundStyle(palette.textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(palette.surface)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(palette.border, lineWidth: 1)
                                )
                        }
                        .principlePanel(palette)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Reason")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(palette.textMuted)
                                .textCase(.uppercase)

                            TextEditor(text: $description)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 170)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(palette.textPrimary)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(palette.surface)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(palette.border, lineWidth: 1)
                                )
                        }
                        .principlePanel(palette)

                        Toggle(isOn: $markToday) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Count today as day one")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(palette.textPrimary)

                                Text("Useful when the principle is already active in your mind right now.")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(palette.textSecondary)
                            }
                        }
                        .toggleStyle(.switch)
                        .tint(palette.accent)
                        .principlePanel(palette)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("New Principle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            return
        }

        let principle = Principle(
            title: trimmedTitle,
            principleDescription: trimmedDescription.isEmpty
                ? "Why this principle matters can be refined over time."
                : trimmedDescription
        )

        modelContext.insert(principle)

        if markToday {
            toggleCheckIn(for: principle, using: modelContext)
        } else {
            try? modelContext.save()
        }

        dismiss()
    }
}

private struct TrackerHeaderRow: View {
    let dates: [Date]
    let palette: ThemePalette

    var body: some View {
        HStack(spacing: 12) {
            Text("Principle")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(palette.textMuted)
                .textCase(.uppercase)
                .frame(width: 248, alignment: .leading)

            HStack(spacing: 6) {
                ForEach(dates, id: \.self) { date in
                    VStack(spacing: 4) {
                        Text(date.formatted(.dateTime.weekday(.narrow)))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(palette.textMuted)

                        Text(date.formatted(.dateTime.day()))
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(palette.textSecondary)
                    }
                    .frame(width: 24)
                }
            }
        }
    }
}

private struct PrincipleTrackerRow: View {
    let principle: Principle
    let dates: [Date]
    let palette: ThemePalette
    let onToggleToday: () -> Void

    private var stats: PrincipleAnalyticsSnapshot {
        principle.analytics()
    }

    private var states: [PrincipleDayState] {
        PrincipleAnalytics.timelineState(
            checkIns: principle.checkIns.map(\.day),
            count: dates.count
        )
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggleToday) {
                TodayOrb(
                    isCompleted: stats.completedToday,
                    palette: palette
                )
            }
            .buttonStyle(.plain)

            NavigationLink(value: principle) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(principle.title)
                            .font(.system(size: 21, weight: .semibold, design: .serif))
                            .foregroundStyle(palette.textPrimary)
                            .lineLimit(1)

                        statusChip
                    }

                    Text(principle.principleDescription)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        MetricPill(
                            title: "\(stats.currentStreak) day streak",
                            accent: palette.accent,
                            fill: palette.accentSoft,
                            foreground: palette.textPrimary
                        )

                        MetricPill(
                            title: stats.hasGraduated
                                ? "graduated"
                                : "\(stats.remainingToGraduate) left",
                            accent: palette.textMuted,
                            fill: palette.surface,
                            foreground: palette.textSecondary
                        )
                    }
                }
                .frame(width: 190, alignment: .leading)
            }
            .buttonStyle(.plain)

            HStack(spacing: 6) {
                ForEach(states) { state in
                    TrackerDayCell(
                        state: state,
                        palette: palette
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var statusStyle: (title: String, fill: Color, foreground: Color) {
        if stats.hasGraduated {
            ("Graduated", palette.accentSoft, palette.accent)
        } else if stats.completedToday {
            ("On track", palette.accentSoft, palette.accent)
        } else if stats.completedYesterday {
            ("Protect today", palette.surface, palette.warning)
        } else {
            ("Restart", palette.surface, palette.textMuted)
        }
    }

    private var statusChip: some View {
        let style = statusStyle

        return Text(style.title)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(style.foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(style.fill)
            )
    }
}

private struct ArchiveCard: View {
    let principle: Principle
    let palette: ThemePalette
    let onRestore: () -> Void

    private var stats: PrincipleAnalyticsSnapshot {
        principle.analytics()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                NavigationLink(value: principle) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(principle.title)
                            .font(.system(size: 25, weight: .semibold, design: .serif))
                            .foregroundStyle(palette.textPrimary)

                        Text(principle.principleDescription)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(palette.textSecondary)
                            .lineLimit(2)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Restore") {
                    onRestore()
                }
                .buttonStyle(.borderedProminent)
                .tint(palette.accent)
            }

            HStack(spacing: 10) {
                MetricPill(
                    title: "best \(stats.longestStreak) days",
                    accent: palette.accent,
                    fill: palette.accentSoft,
                    foreground: palette.textPrimary
                )

                MetricPill(
                    title: principle.graduatedAt == nil
                        ? "archived"
                        : "graduated \(principle.graduatedAt?.formatted(.dateTime.month(.abbreviated).day()) ?? "")",
                    accent: palette.textMuted,
                    fill: palette.surface,
                    foreground: palette.textSecondary
                )
            }
        }
        .principlePanel(palette)
    }
}

private struct TodayOrb: View {
    let isCompleted: Bool
    let palette: ThemePalette

    var body: some View {
        ZStack {
            Circle()
                .fill(isCompleted ? palette.accent : palette.surface)
                .frame(width: 40, height: 40)

            Circle()
                .stroke(isCompleted ? palette.accentGlow.opacity(0.7) : palette.border, lineWidth: 1.5)
                .frame(width: 48, height: 48)

            Image(systemName: isCompleted ? "checkmark" : "plus")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isCompleted ? Color.black.opacity(0.72) : palette.textSecondary)
        }
        .shadow(
            color: isCompleted ? palette.accentGlow.opacity(0.35) : Color.black.opacity(0.08),
            radius: 16,
            y: 6
        )
    }
}

private struct TrackerDayCell: View {
    let state: PrincipleDayState
    let palette: ThemePalette
    var size: CGFloat = 24

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(state.isCompleted ? palette.accent : palette.surface)
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        state.isToday
                            ? palette.accentGlow.opacity(0.9)
                            : (state.isCompleted ? palette.accent.opacity(0.4) : palette.border),
                        lineWidth: state.isToday ? 1.6 : 1
                    )
            )
            .shadow(
                color: state.isCompleted ? palette.accentGlow.opacity(state.isToday ? 0.34 : 0.16) : .clear,
                radius: state.isToday ? 12 : 6,
                y: state.isToday ? 4 : 2
            )
    }
}

private struct SummaryChip: View {
    let title: String
    let value: String
    let icon: String
    let palette: ThemePalette

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(palette.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 17, weight: .bold, design: .monospaced))
                    .foregroundStyle(palette.textPrimary)
                    .monospacedDigit()

                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.textMuted)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(palette.border, lineWidth: 1)
        )
    }
}

private struct MetricPill: View {
    let title: String
    let accent: Color
    let fill: Color
    let foreground: Color

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(fill)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(accent.opacity(0.24), lineWidth: 1)
            )
    }
}

private struct MetricTile: View {
    let title: String
    let value: String
    let detail: String
    let palette: ThemePalette

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(palette.textMuted)
                .textCase(.uppercase)

            Text(value)
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .foregroundStyle(palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(detail)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
        .principlePanel(palette)
    }
}

private struct ProgressRing: View {
    let progress: Double
    let label: String
    let value: Int
    let palette: ThemePalette

    var body: some View {
        ZStack {
            Circle()
                .stroke(palette.surface, lineWidth: 14)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [palette.accentGlow, palette.accent, palette.accentGlow],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 3) {
                Text("\(value)")
                    .font(.system(size: 34, weight: .bold, design: .monospaced))
                    .foregroundStyle(palette.textPrimary)
                    .monospacedDigit()

                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(palette.textMuted)
            }
        }
        .frame(width: 120, height: 120)
        .shadow(color: palette.accentGlow.opacity(0.25), radius: 18, y: 8)
    }
}

private struct AccentSwatch: View {
    let accent: AccentPalette
    let scheme: ColorScheme
    let isSelected: Bool
    let palette: ThemePalette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                accent.accent(for: scheme),
                                accent.accentGlow(for: scheme)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 54)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? palette.textPrimary : palette.border, lineWidth: isSelected ? 1.6 : 1)
                    )

                HStack {
                    Text(accent.title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(palette.textPrimary)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(palette.accent)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(palette.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AtmosphereBackground: View {
    let palette: ThemePalette

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [palette.backgroundTop, palette.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(palette.accent.opacity(0.13))
                .frame(width: 280, height: 280)
                .blur(radius: 36)
                .offset(x: 120, y: -260)

            Circle()
                .fill(palette.accentGlow.opacity(0.1))
                .frame(width: 320, height: 320)
                .blur(radius: 48)
                .offset(x: -150, y: 260)

            VStack(spacing: 28) {
                ForEach(0..<18, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.02))
                        .frame(height: 1)
                }
            }
            .rotationEffect(.degrees(-6))
            .scaleEffect(1.3)
        }
        .ignoresSafeArea()
    }
}

private extension View {
    func principlePanel(_ palette: ThemePalette, glow: Bool = false) -> some View {
        self
            .padding(20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [palette.cardStrong, palette.card],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(palette.border, lineWidth: 1)
                }
            )
            .shadow(
                color: glow ? palette.accentGlow.opacity(0.18) : Color.black.opacity(0.08),
                radius: glow ? 24 : 14,
                y: 8
            )
    }
}

private func toggleCheckIn(
    for principle: Principle,
    using modelContext: ModelContext,
    date: Date = .now,
    calendar: Calendar = .current
) {
    let day = calendar.startOfDay(for: date)

    if let existing = principle.checkIns.first(where: { calendar.isDate($0.day, inSameDayAs: day) }) {
        principle.checkIns.removeAll { $0.id == existing.id }
        modelContext.delete(existing)
    } else {
        let checkIn = PrincipleCheckIn(day: day)
        principle.checkIns.append(checkIn)
        modelContext.insert(checkIn)
    }

    principle.updatedAt = .now

    let stats = principle.analytics(now: day, calendar: calendar)
    if stats.currentStreak >= principle.targetDays && principle.graduatedAt == nil {
        principle.graduatedAt = day
        principle.archivedAt = principle.archivedAt ?? day
    }

    try? modelContext.save()
}
