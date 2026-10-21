//
//  AppearanceStore.swift
//  Principles
//
//  Created by Codex on 2026-03-10.
//

import Combine
import SwiftUI

enum AppAppearancePreference: String, CaseIterable, Identifiable {
    case dark
    case light
    case system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dark: "Dark"
        case .light: "Light"
        case .system: "System"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .dark: .dark
        case .light: .light
        case .system: nil
        }
    }
}

enum AccentPalette: String, CaseIterable, Identifiable {
    case ember
    case jade
    case atlas
    case sun
    case rose

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ember: "Ember"
        case .jade: "Jade"
        case .atlas: "Atlas"
        case .sun: "Sun"
        case .rose: "Rose"
        }
    }

    func accent(for scheme: ColorScheme) -> Color {
        switch (self, scheme) {
        case (.ember, .dark): Color(hex: "#FF7A45")
        case (.ember, .light): Color(hex: "#A9491C")
        case (.jade, .dark): Color(hex: "#3DD7A8")
        case (.jade, .light): Color(hex: "#14674A")
        case (.atlas, .dark): Color(hex: "#6CC5FF")
        case (.atlas, .light): Color(hex: "#1E6A96")
        case (.sun, .dark): Color(hex: "#FFD166")
        case (.sun, .light): Color(hex: "#9B6900")
        case (.rose, .dark): Color(hex: "#FF8AA3")
        case (.rose, .light): Color(hex: "#A63D5A")
        @unknown default: Color(hex: "#6CC5FF")
        }
    }

    func accentSoft(for scheme: ColorScheme) -> Color {
        switch (self, scheme) {
        case (.ember, .dark): Color(hex: "#4B2617")
        case (.ember, .light): Color(hex: "#F8D8CC")
        case (.jade, .dark): Color(hex: "#14392D")
        case (.jade, .light): Color(hex: "#D5F3E8")
        case (.atlas, .dark): Color(hex: "#142F44")
        case (.atlas, .light): Color(hex: "#D8EDF9")
        case (.sun, .dark): Color(hex: "#4C380A")
        case (.sun, .light): Color(hex: "#FAEBC6")
        case (.rose, .dark): Color(hex: "#48202A")
        case (.rose, .light): Color(hex: "#F6D8E1")
        @unknown default: Color(hex: "#142F44")
        }
    }

    func accentGlow(for scheme: ColorScheme) -> Color {
        switch (self, scheme) {
        case (.ember, .dark): Color(hex: "#FFC0A3")
        case (.ember, .light): Color(hex: "#F2A786")
        case (.jade, .dark): Color(hex: "#86FFD6")
        case (.jade, .light): Color(hex: "#5BCBA5")
        case (.atlas, .dark): Color(hex: "#B6E5FF")
        case (.atlas, .light): Color(hex: "#7BBFE7")
        case (.sun, .dark): Color(hex: "#FFE8A8")
        case (.sun, .light): Color(hex: "#E2B454")
        case (.rose, .dark): Color(hex: "#FFC3D0")
        case (.rose, .light): Color(hex: "#DF8FA5")
        @unknown default: Color(hex: "#B6E5FF")
        }
    }
}

struct ThemePalette {
    let backgroundTop: Color
    let backgroundBottom: Color
    let card: Color
    let cardStrong: Color
    let surface: Color
    let surfaceMuted: Color
    let border: Color
    let textPrimary: Color
    let textSecondary: Color
    let textMuted: Color
    let accent: Color
    let accentSoft: Color
    let accentGlow: Color
    let success: Color
    let warning: Color
}

@MainActor
final class ThemeStore: ObservableObject {
    private enum Key {
        static let appearance = "theme.appearance"
        static let darkAccent = "theme.darkAccent"
        static let lightAccent = "theme.lightAccent"
        static let visibleHistoryDays = "theme.visibleHistoryDays"
    }

    private let defaults: UserDefaults
    let historyOptions = [3, 4, 5]
    let defaultHistoryDays = 5

    @Published var appearance: AppAppearancePreference {
        didSet { save() }
    }

    @Published var darkAccent: AccentPalette {
        didSet { save() }
    }

    @Published var lightAccent: AccentPalette {
        didSet { save() }
    }

    @Published var visibleHistoryDays: Int {
        didSet {
            if !historyOptions.contains(visibleHistoryDays) {
                visibleHistoryDays = defaultHistoryDays
            }
            save()
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        appearance = AppAppearancePreference(
            rawValue: defaults.string(forKey: Key.appearance) ?? ""
        ) ?? .dark
        darkAccent = AccentPalette(
            rawValue: defaults.string(forKey: Key.darkAccent) ?? ""
        ) ?? .atlas
        lightAccent = AccentPalette(
            rawValue: defaults.string(forKey: Key.lightAccent) ?? ""
        ) ?? .ember

        let storedHistory = defaults.integer(forKey: Key.visibleHistoryDays)
        visibleHistoryDays = historyOptions.contains(storedHistory) ? storedHistory : defaultHistoryDays
    }

    var preferredColorScheme: ColorScheme? {
        appearance.preferredColorScheme
    }

    func accentSelection(for scheme: ColorScheme) -> AccentPalette {
        switch scheme {
        case .dark:
            darkAccent
        case .light:
            lightAccent
        @unknown default:
            darkAccent
        }
    }

    func palette(for scheme: ColorScheme) -> ThemePalette {
        let accent = accentSelection(for: scheme)

        switch scheme {
        case .dark:
            return ThemePalette(
                backgroundTop: Color(hex: "#07090E"),
                backgroundBottom: Color(hex: "#131C26"),
                card: Color(hex: "#111822"),
                cardStrong: Color(hex: "#18222E"),
                surface: Color(hex: "#0C1219"),
                surfaceMuted: Color(hex: "#202B38"),
                border: Color.white.opacity(0.08),
                textPrimary: Color(hex: "#F4EEDF"),
                textSecondary: Color(hex: "#B8C1CC"),
                textMuted: Color(hex: "#7F8997"),
                accent: accent.accent(for: .dark),
                accentSoft: accent.accentSoft(for: .dark),
                accentGlow: accent.accentGlow(for: .dark),
                success: Color(hex: "#52E0A1"),
                warning: Color(hex: "#FFD166")
            )
        case .light:
            return ThemePalette(
                backgroundTop: Color(hex: "#F6F0E4"),
                backgroundBottom: Color(hex: "#EDE3D2"),
                card: Color.white.opacity(0.86),
                cardStrong: Color(hex: "#FFF9F0"),
                surface: Color(hex: "#FBF4E8"),
                surfaceMuted: Color(hex: "#E6DCCB"),
                border: Color.black.opacity(0.08),
                textPrimary: Color(hex: "#1C160E"),
                textSecondary: Color(hex: "#625647"),
                textMuted: Color(hex: "#938673"),
                accent: accent.accent(for: .light),
                accentSoft: accent.accentSoft(for: .light),
                accentGlow: accent.accentGlow(for: .light),
                success: Color(hex: "#1D8B63"),
                warning: Color(hex: "#AA7608")
            )
        @unknown default:
            return palette(for: .dark)
        }
    }

    private func save() {
        defaults.set(appearance.rawValue, forKey: Key.appearance)
        defaults.set(darkAccent.rawValue, forKey: Key.darkAccent)
        defaults.set(lightAccent.rawValue, forKey: Key.lightAccent)
        defaults.set(visibleHistoryDays, forKey: Key.visibleHistoryDays)
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let r, g, b, a: UInt64

        switch cleaned.count {
        case 3:
            (r, g, b, a) = (
                ((value >> 8) & 0xF) * 17,
                ((value >> 4) & 0xF) * 17,
                (value & 0xF) * 17,
                255
            )
        case 6:
            (r, g, b, a) = (
                (value >> 16) & 0xFF,
                (value >> 8) & 0xFF,
                value & 0xFF,
                255
            )
        case 8:
            (r, g, b, a) = (
                (value >> 24) & 0xFF,
                (value >> 16) & 0xFF,
                (value >> 8) & 0xFF,
                value & 0xFF
            )
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
