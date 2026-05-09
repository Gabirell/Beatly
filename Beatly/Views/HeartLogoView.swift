//
//  HeartLogoView.swift
//  Beatly
//
//  Created by Gabriel Netto on 30/04/26.
//

import SwiftUI

/// Animated heart with headphones logo — adapts to current theme and heart rate zone color
struct HeartLogoView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    
    /// The BPM-based zone color (overrides theme heart color when active)
    var zoneColor: Color?
    
    /// Size multiplier (1.0 = default 280pt frame)
    var scale: CGFloat = 1.0
    
    /// Whether the pulse animation is running
    var isPulsing: Bool = true
    
    /// Pulse speed — seconds per beat (e.g. 60/BPM)
    var pulseSpeed: Double = 1.0
    
    @State private var animatePulse = false
    @State private var glowPhase: CGFloat = 0
    
    private var activeColor: Color {
        zoneColor ?? themeManager.currentTheme.heartColor
    }
    
    var body: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .fill(
                    RadialGradient(
                        colors: [activeColor.opacity(0.3), activeColor.opacity(0.0)],
                        center: .center,
                        startRadius: 60 * scale,
                        endRadius: 140 * scale
                    )
                )
                .frame(width: 280 * scale, height: 280 * scale)
                .scaleEffect(animatePulse ? 1.15 : 0.9)
                .opacity(animatePulse ? 0.4 : 0.7)
            
            // Secondary glow ring (offset timing for depth)
            Circle()
                .stroke(activeColor.opacity(0.15), lineWidth: 2 * scale)
                .frame(width: 220 * scale, height: 220 * scale)
                .scaleEffect(animatePulse ? 1.1 : 0.95)
            
            // Heart symbol
            Image(systemName: "heart.fill")
                .font(.system(size: 120 * scale, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [activeColor, activeColor.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(animatePulse ? 1.08 : 1.0)
                .shadow(color: activeColor.opacity(0.6), radius: 20 * scale)
                .shadow(color: activeColor.opacity(0.3), radius: 40 * scale)
                .offset(y: 20 * scale)
            
            // Headphones overlaid on heart
            Image(systemName: "headphones")
                .font(.system(size: 150 * scale, weight: .bold))
                .foregroundStyle(
                    themeManager.currentTheme.headphoneColor.opacity(
                        colorScheme == .dark ? 0.95 : 0.9
                    )
                )
                .scaleEffect(animatePulse ? 1.08 : 1.0)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.1), radius: 8 * scale)
                .offset(y: -30 * scale)
            
            // Tiny beat indicator dots around the heart
            ForEach(0..<4) { i in
                Circle()
                    .fill(activeColor)
                    .frame(width: 6 * scale, height: 6 * scale)
                    .offset(y: -130 * scale)
                    .rotationEffect(.degrees(Double(i) * 90 + 45))
                    .scaleEffect(animatePulse ? 1.0 : 0.3)
                    .opacity(animatePulse ? 0.8 : 0.0)
            }
        }
        .frame(width: 280 * scale, height: 280 * scale)
        .fixedSize()
        .animation(
            isPulsing
                ? .easeInOut(duration: pulseSpeed).repeatForever(autoreverses: true)
                : .default,
            value: animatePulse
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animatePulse = true
            }
        }
    }
}

/// Smaller version of the heart logo for use in tab bar or compact areas
struct HeartLogoCompact: View {
    @Environment(ThemeManager.self) private var themeManager
    
    var size: CGFloat = 28
    
    var body: some View {
        ZStack {
            Image(systemName: "heart.fill")
                .font(.system(size: size * 0.7, weight: .semibold))
                .foregroundStyle(themeManager.currentTheme.heartColor.gradient)
                .offset(y: size * 0.06)
            
            Image(systemName: "headphones")
                .font(.system(size: size * 0.85, weight: .bold))
                .foregroundStyle(themeManager.currentTheme.headphoneColor.opacity(0.9))
                .offset(y: -size * 0.12)
        }
        .frame(width: size, height: size)
    }
}

#Preview("HeartLogoView") {
    VStack(spacing: 40) {
        HeartLogoView(zoneColor: .red)
        HeartLogoView(zoneColor: .blue, scale: 0.5)
        HeartLogoCompact()
    }
    .environment(ThemeManager())
}

#Preview("All Themes") {
    ScrollView(.horizontal) {
        HStack(spacing: 30) {
            ForEach(BeatlyTheme.allThemes) { theme in
                VStack {
                    HeartLogoView(scale: 0.5)
                        .environment(ThemeManager.preview(theme: theme))
                    Text(theme.name)
                        .font(.caption)
                }
            }
        }
        .padding()
    }
}

extension ThemeManager {
    static func preview(theme: BeatlyTheme) -> ThemeManager {
        let manager = ThemeManager()
        manager.currentTheme = theme
        return manager
    }
}
