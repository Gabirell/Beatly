//
//  BeatlyApp.swift
//  Beatly
//
//  Created by Gabriel Netto on 10/04/26.
//

import SwiftUI

@main
struct BeatlyApp: App {
    @State private var spotifyManager = SpotifyManager()
    @State private var healthKitManager = HealthKitManager()
    @State private var locationManager = LocationManager()
    @State private var musicKitManager = MusicKitManager()
    @State private var stravaManager = StravaManager()
    @State private var playbackManager = PlaybackManager()
    @State private var workoutPlaylistManager = WorkoutPlaylistManager()
    @State private var youtubeMusicManager = YouTubeMusicManager()
    @State private var deezerManager = DeezerManager()
    @State private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(spotifyManager)
                .environment(healthKitManager)
                .environment(locationManager)
                .environment(musicKitManager)
                .environment(stravaManager)
                .environment(playbackManager)
                .environment(workoutPlaylistManager)
                .environment(youtubeMusicManager)
                .environment(deezerManager)
                .environment(themeManager)
                .onOpenURL { url in
                    handleCallback(url: url)
                }
        }
    }
    
    /// Route OAuth callbacks to the appropriate manager
    private func handleCallback(url: URL) {
        print("🔗 Received URL: \(url.absoluteString)")
        
        let scheme = url.scheme ?? ""
        
        // Google OAuth uses a reversed client ID as the scheme
        // e.g. com.googleusercontent.apps.123456789-xxx:/oauthredirect?code=...
        if scheme.hasPrefix("com.googleusercontent.apps.") {
            handleYouTubeCallback(url: url)
            return
        }
        
        guard scheme == "beatly" else { return }
        
        switch url.host {
        case "callback":
            handleSpotifyCallback(url: url)
        case "strava-callback":
            handleStravaCallback(url: url)
        case "deezer-callback":
            handleDeezerCallback(url: url)
        default:
            print("❌ Unknown callback host: \(url.host ?? "nil")")
        }
    }
    
    /// Handle Spotify OAuth callback
    private func handleSpotifyCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            print("❌ No authorization code found in Spotify URL")
            return
        }
        
        print("✅ Got Spotify authorization code: \(code)")
        
        Task {
            do {
                try await spotifyManager.exchangeCodeForToken(code: code)
                print("✅ Successfully authenticated with Spotify!")
                
                // Auto-fetch playlists and organize by BPM after login
                try await spotifyManager.fetchTopTracks()
                try await spotifyManager.organizeTracksByBPM()
                print("✅ Auto-loaded music after Spotify login")
            } catch {
                print("❌ Error during Spotify login: \(error)")
            }
        }
    }
    
    /// Handle Strava OAuth callback
    private func handleStravaCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            print("❌ No authorization code found in Strava URL")
            return
        }
        
        print("✅ Got Strava authorization code: \(code)")
        
        Task {
            do {
                try await stravaManager.exchangeCodeForToken(code: code)
                print("✅ Successfully authenticated with Strava!")
            } catch {
                print("❌ Error exchanging Strava code: \(error)")
            }
        }
    }
    
    /// Handle YouTube Music OAuth callback
    private func handleYouTubeCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            print("❌ No authorization code found in YouTube URL")
            return
        }
        
        print("✅ Got YouTube Music authorization code: \(code)")
        
        Task {
            do {
                try await youtubeMusicManager.exchangeCodeForToken(code: code)
                print("✅ Successfully authenticated with YouTube Music!")
            } catch {
                print("❌ Error exchanging YouTube code: \(error)")
            }
        }
    }
    
    /// Handle Deezer OAuth callback
    private func handleDeezerCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            print("❌ No authorization code found in Deezer URL")
            return
        }
        
        print("✅ Got Deezer authorization code: \(code)")
        
        Task {
            do {
                try await deezerManager.exchangeCodeForToken(code: code)
                print("✅ Successfully authenticated with Deezer!")
            } catch {
                print("❌ Error exchanging Deezer code: \(error)")
            }
        }
    }
}
