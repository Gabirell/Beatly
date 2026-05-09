//
//  ContentView.swift
//  Beatly
//
//  Created by Gabriel Netto on 10/04/26.
//

import SwiftUI

/// ContentView is the entry point of the app
/// It displays the main tab navigation
struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
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
