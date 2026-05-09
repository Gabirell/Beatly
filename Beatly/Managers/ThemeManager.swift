//
//  ThemeManager.swift
//  Beatly
//
//  Created by Gabriel Netto on 30/04/26.
//

import SwiftUI

// MARK: - Theme Definition

struct BeatlyTheme: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    
    // Accent & brand colors
    let accentColor: Color
    let heartColor: Color
    let headphoneColor: Color
    
    // Background
    let backgroundGradientLight: [Color]
    let backgroundGradientDark: [Color]
    
    // Glow
    let glowColor: Color
    
    func backgroundGradient(for scheme: ColorScheme) -> [Color] {
        scheme == .dark ? backgroundGradientDark : backgroundGradientLight
    }
    
    static func == (lhs: BeatlyTheme, rhs: BeatlyTheme) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Built-in Themes

extension BeatlyTheme {
    
    /// Classic — pink/red heart, white headphones
    static let classic = BeatlyTheme(
        id: "classic",
        name: "Classic",
        icon: "heart.fill",
        accentColor: .pink,
        heartColor: .pink,
        headphoneColor: .white,
        backgroundGradientLight: [Color(.systemBackground), Color.pink.opacity(0.05)],
        backgroundGradientDark: [Color(.systemBackground), Color.pink.opacity(0.1)],
        glowColor: .pink
    )
    
    /// Neon Pulse — electric cyan heart, magenta headphones
    static let neonPulse = BeatlyTheme(
        id: "neonPulse",
        name: "Neon Pulse",
        icon: "bolt.heart.fill",
        accentColor: .cyan,
        heartColor: .cyan,
        headphoneColor: .white,
        backgroundGradientLight: [Color(.systemBackground), Color.cyan.opacity(0.06)],
        backgroundGradientDark: [Color(.systemBackground), Color.cyan.opacity(0.15)],
        glowColor: .cyan
    )
    
    /// Sunset — warm orange heart, golden headphones
    static let sunset = BeatlyTheme(
        id: "sunset",
        name: "Sunset",
        icon: "sun.max.fill",
        accentColor: .orange,
        heartColor: .orange,
        headphoneColor: .white,
        backgroundGradientLight: [Color(.systemBackground), Color.orange.opacity(0.06)],
        backgroundGradientDark: [Color(.systemBackground), Color.orange.opacity(0.12)],
        glowColor: .orange
    )
    
    /// Midnight — deep purple heart, silver headphones
    static let midnight = BeatlyTheme(
        id: "midnight",
        name: "Midnight",
        icon: "moon.stars.fill",
        accentColor: .purple,
        heartColor: .purple,
        headphoneColor: .white,
        backgroundGradientLight: [Color(.systemBackground), Color.purple.opacity(0.05)],
        backgroundGradientDark: [Color(.systemBackground), Color.purple.opacity(0.15)],
        glowColor: .purple
    )
    
    /// Nature — green heart, earthy headphones
    static let nature = BeatlyTheme(
        id: "nature",
        name: "Nature",
        icon: "leaf.fill",
        accentColor: .green,
        heartColor: .green,
        headphoneColor: .white,
        backgroundGradientLight: [Color(.systemBackground), Color.green.opacity(0.05)],
        backgroundGradientDark: [Color(.systemBackground), Color.green.opacity(0.12)],
        glowColor: .green
    )
    
    static let allThemes: [BeatlyTheme] = [.classic, .neonPulse, .sunset, .midnight, .nature]
}

// MARK: - Theme Manager

@Observable
class ThemeManager {
    
    var currentTheme: BeatlyTheme = .classic
    
    private let storageKey = "selectedThemeId"
    
    init() {
        load()
    }
    
    func selectTheme(_ theme: BeatlyTheme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.id, forKey: storageKey)
    }
    
    private func load() {
        guard let savedId = UserDefaults.standard.string(forKey: storageKey),
              let theme = BeatlyTheme.allThemes.first(where: { $0.id == savedId }) else { return }
        currentTheme = theme
    }
}
