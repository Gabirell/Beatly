//
//  ProfileView.swift
//  Beatly
//
//  Created by Gabriel Netto on 10/04/26.
//

import SwiftUI

/// ProfileView displays user settings and service connections
/// Users can connect/disconnect Spotify, Apple Music, HealthKit, Strava, and Location Services
struct ProfileView: View {
    @Environment(SpotifyManager.self) private var spotifyManager
    @Environment(HealthKitManager.self) private var healthKitManager
    @Environment(LocationManager.self) private var locationManager
    @Environment(MusicKitManager.self) private var musicKitManager
    @Environment(StravaManager.self) private var stravaManager
    @Environment(YouTubeMusicManager.self) private var youtubeMusicManager
    @Environment(DeezerManager.self) private var deezerManager
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.openURL) private var openURL
    
    @State private var showingSpotifyLogin = false
    
    var body: some View {
        NavigationStack {
            List {
                // User Info Section
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(.purple.gradient)
                            .frame(width: 60, height: 60)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.title)
                                    .foregroundStyle(.white)
                            }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome!")
                                .font(.title3.bold())
                            Text("Manage your connections")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Music Services
                Section("Music") {
                    // Spotify
                    ServiceRow(
                        icon: "music.note",
                        iconColor: .green,
                        title: "Spotify",
                        subtitle: spotifyManager.isAuthenticated ? "Connected" : "Not connected",
                        isConnected: spotifyManager.isAuthenticated
                    ) {
                        if spotifyManager.isAuthenticated {
                            spotifyManager.disconnect()
                        } else {
                            showingSpotifyLogin = true
                        }
                    }
                    
                    // Apple Music
                    ServiceRow(
                        icon: "music.note.tv",
                        iconColor: .pink,
                        title: "Apple Music",
                        subtitle: musicKitManager.statusText,
                        isConnected: musicKitManager.isAuthorized
                    ) {
                        Task {
                            await musicKitManager.requestAuthorization()
                        }
                    }
                    
                    // YouTube Music
                    ServiceRow(
                        icon: "play.rectangle.fill",
                        iconColor: .red,
                        title: "YouTube Music",
                        subtitle: youtubeMusicManager.statusText,
                        isConnected: youtubeMusicManager.isAuthenticated
                    ) {
                        if youtubeMusicManager.isAuthenticated {
                            youtubeMusicManager.disconnect()
                        } else {
                            if let url = youtubeMusicManager.getAuthorizationURL() {
                                openURL(url)
                            }
                        }
                    }
                    
                    // Deezer
                    ServiceRow(
                        icon: "waveform",
                        iconColor: .purple,
                        title: "Deezer",
                        subtitle: deezerManager.statusText,
                        isConnected: deezerManager.isAuthenticated
                    ) {
                        if deezerManager.isAuthenticated {
                            deezerManager.disconnect()
                        } else {
                            if let url = deezerManager.getAuthorizationURL() {
                                openURL(url)
                            }
                        }
                    }
                }
                
                // Health & Fitness
                Section("Health & Fitness") {
                    // HealthKit
                    ServiceRow(
                        icon: "heart.fill",
                        iconColor: .red,
                        title: "Health Data",
                        subtitle: healthKitManager.isAuthorized ? "Authorized" : "Not connected",
                        isConnected: healthKitManager.isAuthorized
                    ) {
                        if !healthKitManager.isAuthorized {
                            Task {
                                try? await healthKitManager.requestAuthorization()
                            }
                        }
                    }
                    
                    // Strava
                    ServiceRow(
                        icon: "figure.run",
                        iconColor: .orange,
                        title: "Strava",
                        subtitle: stravaManager.isAuthenticated
                            ? "Connected as \(stravaManager.athleteName ?? "Athlete")"
                            : "Not connected",
                        isConnected: stravaManager.isAuthenticated
                    ) {
                        if stravaManager.isAuthenticated {
                            stravaManager.disconnect()
                        } else {
                            if let url = stravaManager.getAuthorizationURL() {
                                openURL(url)
                            }
                        }
                    }
                    
                    // Location Services
                    ServiceRow(
                        icon: "location.fill",
                        iconColor: .blue,
                        title: "Location Services",
                        subtitle: locationManager.statusText,
                        isConnected: locationManager.isAuthorized
                    ) {
                        locationManager.requestPermission()
                    }
                }
                
                // Theme
                Section("Theme") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(BeatlyTheme.allThemes) { theme in
                                Button {
                                    themeManager.selectTheme(theme)
                                } label: {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(theme.heartColor.gradient)
                                                .frame(width: 50, height: 50)
                                            
                                            Image(systemName: "heart.fill")
                                                .font(.system(size: 18))
                                                .foregroundStyle(.white.opacity(0.9))
                                                .offset(y: 3)
                                            
                                            Image(systemName: "headphones")
                                                .font(.system(size: 22, weight: .bold))
                                                .foregroundStyle(.white)
                                                .offset(y: -4)
                                        }
                                        .overlay {
                                            if themeManager.currentTheme.id == theme.id {
                                                Circle()
                                                    .stroke(theme.heartColor, lineWidth: 3)
                                                    .frame(width: 56, height: 56)
                                            }
                                        }
                                        
                                        Text(theme.name)
                                            .font(.caption2)
                                            .foregroundStyle(
                                                themeManager.currentTheme.id == theme.id
                                                    ? theme.heartColor
                                                    : .secondary
                                            )
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // App Settings
                Section("Settings") {
                    SettingsRow(
                        icon: "bell.fill",
                        iconColor: .blue,
                        title: "Notifications",
                        subtitle: "Manage alerts"
                    )
                    
                    SettingsRow(
                        icon: "shield.fill",
                        iconColor: .green,
                        title: "Privacy & Safety",
                        subtitle: "Location sharing and alerts"
                    )
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingSpotifyLogin) {
                SpotifyLoginView()
            }
        }
    }
}

// MARK: - Service Row (interactive, with connect/disconnect)

struct ServiceRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let isConnected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(iconColor.gradient)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                    }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isConnected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Text("Connect")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
        }
        .tint(.primary)
    }
}

// MARK: - Settings Row (static, display only)

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(iconColor.gradient)
                .frame(width: 32, height: 32)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    ProfileView()
        .environment(SpotifyManager())
        .environment(HealthKitManager())
        .environment(LocationManager())
        .environment(MusicKitManager())
        .environment(StravaManager())
        .environment(YouTubeMusicManager())
        .environment(DeezerManager())
        .environment(ThemeManager())
}
