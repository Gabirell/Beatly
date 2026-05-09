//
//  MainTabView.swift
//  Beatly
//
//  Created by Gabriel Netto on 10/04/26.
//

import SwiftUI

/// MainTabView is the main navigation hub of the app
/// It uses a TabView to let users switch between different sections
struct MainTabView: View {
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        TabView {
            // Home Tab - The main screen with the pulsing heart
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "heart.fill")
                }
            
            // Playlist Tab - Browse and manage music
            PlaylistView()
                .tabItem {
                    Label("Playlists", systemImage: "music.note.list")
                }
            
            // Workout Tab - Plan and track exercises
            WorkoutView()
                .tabItem {
                    Label("Workout", systemImage: "figure.run")
                }
            
            // Profile Tab - User settings and preferences
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(themeManager.currentTheme.accentColor)
    }
}

#Preview {
    MainTabView()
        .environment(SpotifyManager())
        .environment(HealthKitManager())
        .environment(LocationManager())
        .environment(MusicKitManager())
        .environment(StravaManager())
        .environment(PlaybackManager())
        .environment(WorkoutPlaylistManager())
        .environment(YouTubeMusicManager())
        .environment(DeezerManager())
        .environment(ThemeManager())
}
