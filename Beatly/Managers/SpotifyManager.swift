//
//  SpotifyManager.swift
//  Beatly
//
//  Created by Gabriel Netto on 10/04/26.
//

import Foundation
import SwiftUI

/// Manages all Spotify API interactions including authentication and music data
/// Handles BPM analysis and playlist creation based on heart rate zones
@Observable
class SpotifyManager {
    
    // MARK: - Properties
    
    /// Spotify credentials — stored in Secrets.swift (git-ignored)
    private let clientID = Secrets.spotifyClientID
    private let clientSecret = Secrets.spotifyClientSecret
    private let redirectURI = Secrets.spotifyRedirectURI
    
    /// Authorization token (received after user logs in)
    var accessToken: String?
    
    /// Whether user is authenticated with Spotify
    var isAuthenticated: Bool {
        accessToken != nil
    }
    
    /// User's top tracks
    var topTracks: [SpotifyTrack] = []
    
    /// Debug: raw API response for troubleshooting
    var debugResponse: String?
    
    /// Tracks organized by BPM zones
    var tracksByZone: [HeartRateZone: [SpotifyTrack]] = [:]
    
    // MARK: - API Helpers
    
    /// Check the HTTP response and throw if Spotify returned an error
    private func validateResponse(_ data: Data, _ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SpotifyError.networkError
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? "no body"
            print("❌ Spotify API error (\(httpResponse.statusCode)): \(bodyString)")
            
            // Try to decode Spotify's error response
            if let apiError = try? JSONDecoder().decode(SpotifyAPIError.self, from: data) {
                throw SpotifyError.apiError(status: apiError.error.status, message: apiError.error.message)
            }
            throw SpotifyError.apiError(status: httpResponse.statusCode, message: bodyString)
        }
    }
    
    // MARK: - Authentication
    
    /// Get the authorization URL for Spotify login
    func getAuthorizationURL() -> URL? {
        var components = URLComponents(string: "https://accounts.spotify.com/authorize")!
        
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: "user-read-private user-read-email playlist-read-private playlist-modify-public playlist-modify-private user-top-read user-library-read")
        ]
        
        guard let url = components.url else {
            print("❌ Failed to create authorization URL")
            return nil
        }
        
        print("🔗 Authorization URL: \(url.absoluteString)")
        
        return url
    }
    
    /// Exchange authorization code for access token
    func exchangeCodeForToken(code: String) async throws {
        let tokenURL = URL(string: "https://accounts.spotify.com/api/token")!
        
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Create authorization header (Base64 encoded clientID:clientSecret)
        let credentials = "\(clientID):\(clientSecret)"
        let credentialsData = credentials.data(using: .utf8)!
        let base64Credentials = credentialsData.base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        
        // Request body
        let bodyString = "grant_type=authorization_code&code=\(code)&redirect_uri=\(redirectURI)"
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(data, response)
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        await MainActor.run {
            self.accessToken = tokenResponse.access_token
        }
    }
    
    // MARK: - Fetch User's Playlists & Tracks
    
    /// User's playlists
    var playlists: [SpotifyPlaylist] = []
    
    /// Fetch user profile to get user ID and verify token
    private func fetchUserProfile(token: String) async -> SpotifyUser? {
        let url = URL(string: "https://api.spotify.com/v1/me")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            try validateResponse(data, response)
            let user = try JSONDecoder().decode(SpotifyUser.self, from: data)
            print("✅ User profile: \(user.display_name ?? "unknown") (id: \(user.id))")
            return user
        } catch {
            print("⚠️ Failed to fetch user profile: \(error)")
            return nil
        }
    }
    
    /// Try to fetch user's own playlists, fall back to search
    func fetchTopTracks() async throws {
        guard let token = accessToken else {
            throw SpotifyError.notAuthenticated
        }
        
        var allTracks: [SpotifyTrack] = []
        var seen = Set<String>()
        
        // Step 1: Get user profile for user ID
        let user = await fetchUserProfile(token: token)
        
        // Step 2: Try personal playlists
        if let userId = user?.id {
            let personalTracks = await fetchPersonalPlaylists(token: token, userId: userId)
            for track in personalTracks where seen.insert(track.id).inserted {
                allTracks.append(track)
            }
            print("📋 Playlist tracks: \(personalTracks.count)")
        }
        
        // Step 3: Try user's top tracks
        let userTopTracks = await fetchUserTopTracks(token: token)
        for track in userTopTracks where seen.insert(track.id).inserted {
            allTracks.append(track)
        }
        print("🔝 Top tracks: \(userTopTracks.count)")
        
        // Step 4: Try user's saved/liked songs
        let savedTracks = await fetchSavedTracks(token: token)
        for track in savedTracks where seen.insert(track.id).inserted {
            allTracks.append(track)
        }
        print("💚 Saved tracks: \(savedTracks.count)")
        
        // Step 5: If still empty, fall back to search
        if allTracks.isEmpty {
            print("⚠️ No personal music found, falling back to search")
            let searchTracks = await fetchTracksViaSearch(token: token)
            allTracks = searchTracks
        }
        
        await MainActor.run {
            self.topTracks = allTracks
        }
        
        print("✅ Total unique tracks loaded: \(allTracks.count)")
    }
    
    /// Try fetching playlists via /me/playlists and /users/{id}/playlists
    private func fetchPersonalPlaylists(token: String, userId: String) async -> [SpotifyTrack] {
        // Try /me/playlists first
        let endpoints = [
            "https://api.spotify.com/v1/me/playlists?limit=10",
            "https://api.spotify.com/v1/users/\(userId)/playlists?limit=10"
        ]
        
        for endpoint in endpoints {
            guard let url = URL(string: endpoint) else { continue }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                try validateResponse(data, response)
                let playlistsResponse = try JSONDecoder().decode(PlaylistsResponse.self, from: data)
                
                print("✅ Got \(playlistsResponse.items.count) playlists from \(endpoint)")
                
                await MainActor.run {
                    self.playlists = playlistsResponse.items
                }
                
                // Fetch tracks from each playlist
                var allTracks: [SpotifyTrack] = []
                for playlist in playlistsResponse.items {
                    let tracks = await fetchPlaylistTracks(token: token, playlistId: playlist.id, playlistName: playlist.name)
                    allTracks.append(contentsOf: tracks)
                }
                
                // Deduplicate
                var seen = Set<String>()
                return allTracks.filter { seen.insert($0.id).inserted }
            } catch {
                print("⚠️ \(endpoint) failed: \(error)")
                continue
            }
        }
        
        return []
    }
    
    /// Fetch tracks from a specific playlist
    private func fetchPlaylistTracks(token: String, playlistId: String, playlistName: String) async -> [SpotifyTrack] {
        guard let url = URL(string: "https://api.spotify.com/v1/playlists/\(playlistId)/items?limit=50") else { return [] }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            try validateResponse(data, response)
            let playlistTracks = try JSONDecoder().decode(PlaylistTracksResponse.self, from: data)
            let tracks = playlistTracks.items.compactMap { $0.track }
            print("  📋 \(playlistName): \(tracks.count) tracks")
            return tracks
        } catch {
            print("  ⚠️ Skipping playlist \(playlistName): \(error)")
            return []
        }
    }
    
    /// Fetch user's top tracks from Spotify
    private func fetchUserTopTracks(token: String) async -> [SpotifyTrack] {
        guard let url = URL(string: "https://api.spotify.com/v1/me/top/tracks?limit=50&time_range=medium_term") else { return [] }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            try validateResponse(data, response)
            let topTracksResponse = try JSONDecoder().decode(TopTracksResponse.self, from: data)
            print("  🔝 Got \(topTracksResponse.items.count) top tracks")
            return topTracksResponse.items
        } catch {
            print("  ⚠️ Top tracks failed: \(error)")
            return []
        }
    }
    
    /// Fetch user's saved/liked songs
    private func fetchSavedTracks(token: String) async -> [SpotifyTrack] {
        guard let url = URL(string: "https://api.spotify.com/v1/me/tracks?limit=50") else { return [] }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            try validateResponse(data, response)
            let savedResponse = try JSONDecoder().decode(SavedTracksResponse.self, from: data)
            let tracks = savedResponse.items.compactMap { $0.track }
            print("  💚 Got \(tracks.count) saved tracks")
            return tracks
        } catch {
            print("  ⚠️ Saved tracks failed: \(error)")
            return []
        }
    }
    
    /// Fallback: fetch tracks via Search API
    private func fetchTracksViaSearch(token: String) async -> [SpotifyTrack] {
        let genres = ["pop", "rock", "hip hop", "electronic", "latin"]
        var allTracks: [SpotifyTrack] = []
        
        for genre in genres {
            guard let query = "genre:\(genre)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { continue }
            guard let searchURL = URL(string: "https://api.spotify.com/v1/search?q=\(query)&type=track&limit=10") else { continue }
            
            var request = URLRequest(url: searchURL)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                try validateResponse(data, response)
                let searchResponse = try JSONDecoder().decode(SearchResponse.self, from: data)
                allTracks.append(contentsOf: searchResponse.tracks.items)
                print("  🔍 \(genre): \(searchResponse.tracks.items.count) tracks")
            } catch {
                print("  ⚠️ Search failed for \(genre): \(error)")
                continue
            }
        }
        
        var seen = Set<String>()
        return allTracks.filter { seen.insert($0.id).inserted }
    }
    
    // MARK: - Disconnect
    
    /// Disconnect from Spotify and clear all data
    func disconnect() {
        accessToken = nil
        topTracks = []
        playlists = []
        tracksByZone = [:]
        debugResponse = nil
    }
    
    // MARK: - Organize Tracks by BPM
    
    /// Estimate BPM from track name heuristics and organize into zones
    /// Note: Audio Features API is deprecated for dev mode apps
    func organizeTracksByBPM() async throws {
        // Since Audio Features API is no longer available in dev mode,
        // distribute tracks evenly across zones for now
        let shuffled = topTracks.shuffled()
        let zones = HeartRateZone.allCases
        var zoneDict: [HeartRateZone: [SpotifyTrack]] = [:]
        
        for (index, track) in shuffled.enumerated() {
            let zone = zones[index % zones.count]
            zoneDict[zone, default: []].append(track)
        }
        
        await MainActor.run {
            self.tracksByZone = zoneDict
        }
        
        print("✅ Organized \(topTracks.count) tracks into zones")
    }
}

// MARK: - Helper Extensions

extension Array {
    /// Split array into chunks of specified size
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Data Models

/// Spotify track information
struct SpotifyTrack: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let artists: [Artist]?
    let album: Album?
    let duration_ms: Int?
    let preview_url: String?
    
    var artistNames: String {
        (artists ?? []).map { $0.name }.joined(separator: ", ")
    }
}

struct Artist: Codable, Hashable {
    let id: String?
    let name: String
}

struct Album: Codable, Hashable {
    let id: String?
    let name: String?
    let images: [SpotifyImage]?
}

struct SpotifyImage: Codable, Hashable {
    let url: String
    let height: Int?
    let width: Int?
}

/// Heart rate zones matched to BPM
enum HeartRateZone: String, CaseIterable, Codable, Hashable {
    case warmUp = "Warm-up"
    case fatBurn = "Fat Burn"
    case cardio = "Cardio"
    case peak = "Peak"
    case maximum = "Maximum"
    
    static func from(bpm: Int) -> HeartRateZone {
        switch bpm {
        case 0..<90: return .warmUp
        case 90..<120: return .fatBurn
        case 120..<140: return .cardio
        case 140..<160: return .peak
        default: return .maximum
        }
    }
    
    var bpmRange: ClosedRange<Int> {
        switch self {
        case .warmUp: return 60...90
        case .fatBurn: return 90...120
        case .cardio: return 120...140
        case .peak: return 140...160
        case .maximum: return 160...200
        }
    }
    
    var color: Color {
        switch self {
        case .warmUp: return .blue
        case .fatBurn: return .green
        case .cardio: return .orange
        case .peak: return .red
        case .maximum: return .purple
        }
    }
}

// MARK: - User Model

struct SpotifyUser: Codable {
    let id: String
    let display_name: String?
}

// MARK: - API Response Models

struct TokenResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
}

struct PlaylistsResponse: Codable {
    let items: [SpotifyPlaylist]
}

struct SpotifyPlaylist: Codable, Identifiable {
    let id: String
    let name: String
    let images: [SpotifyImage]?
    let tracks: PlaylistTrackInfo?
}

struct PlaylistTrackInfo: Codable {
    let total: Int?
}

struct PlaylistTracksResponse: Codable {
    let items: [PlaylistItem]
}

struct PlaylistItem: Codable {
    let track: SpotifyTrack?
}

struct TopTracksResponse: Codable {
    let items: [SpotifyTrack]
}

struct SavedTracksResponse: Codable {
    let items: [SavedTrackItem]
}

struct SavedTrackItem: Codable {
    let track: SpotifyTrack?
}

struct SearchResponse: Codable {
    let tracks: SearchTracksResponse
}

struct SearchTracksResponse: Codable {
    let items: [SpotifyTrack]
}

// MARK: - Spotify API Error Response

struct SpotifyAPIError: Codable {
    let error: SpotifyAPIErrorDetail
}

struct SpotifyAPIErrorDetail: Codable {
    let status: Int
    let message: String
}

// MARK: - Error Types

enum SpotifyError: Error, LocalizedError {
    case notAuthenticated
    case invalidResponse
    case networkError
    case apiError(status: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please log in to Spotify first"
        case .invalidResponse:
            return "Invalid response from Spotify"
        case .networkError:
            return "Network error occurred"
        case .apiError(let status, let message):
            return "Spotify error (\(status)): \(message)"
        }
    }
}
