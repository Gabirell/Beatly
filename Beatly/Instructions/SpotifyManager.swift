//
//  SpotifyManager.swift
//  Beatly
//
//  Created by Gabriel Netto on 10/04/26.
//

import Foundation

/// Manages all Spotify API interactions including authentication and music data
/// Handles BPM analysis and playlist creation based on heart rate zones
@Observable
class SpotifyManager {
    
    // MARK: - Properties
    
    /// Spotify Client ID (get this from Spotify Developer Dashboard)
    private let clientID = "YOUR_CLIENT_ID_HERE"  // ← Replace with your actual Client ID
    
    /// Spotify Client Secret (keep this private!)
    private let clientSecret = "YOUR_CLIENT_SECRET_HERE"  // ← Replace with actual secret
    
    /// Redirect URI (must match what you set in Spotify Dashboard)
    private let redirectURI = "beatly://callback"
    
    /// Authorization token (received after user logs in)
    var accessToken: String?
    
    /// Whether user is authenticated with Spotify
    var isAuthenticated: Bool {
        accessToken != nil
    }
    
    /// User's top tracks
    var topTracks: [SpotifyTrack] = []
    
    /// Tracks organized by BPM zones
    var tracksByZone: [HeartRateZone: [SpotifyTrack]] = [:]
    
    // MARK: - Authentication
    
    /// Get the authorization URL for Spotify login
    func getAuthorizationURL() -> URL? {
        let scopes = [
            "user-read-private",
            "user-read-email",
            "user-top-read",
            "playlist-modify-public",
            "playlist-modify-private"
        ].joined(separator: "%20")
        
        let urlString = """
        https://accounts.spotify.com/authorize?\
        client_id=\(clientID)&\
        response_type=code&\
        redirect_uri=\(redirectURI)&\
        scope=\(scopes)
        """
        
        return URL(string: urlString)
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
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        await MainActor.run {
            self.accessToken = response.access_token
        }
    }
    
    // MARK: - Fetch User's Top Tracks
    
    /// Fetch user's most played tracks
    func fetchTopTracks() async throws {
        guard let token = accessToken else {
            throw SpotifyError.notAuthenticated
        }
        
        let url = URL(string: "https://api.spotify.com/v1/me/top/tracks?limit=50&time_range=medium_term")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TopTracksResponse.self, from: data)
        
        await MainActor.run {
            self.topTracks = response.items
        }
        
        print("✅ Fetched \(response.items.count) top tracks")
    }
    
    // MARK: - Get Audio Features (BPM)
    
    /// Fetch audio features (including BPM) for a track
    func getAudioFeatures(trackID: String) async throws -> AudioFeatures {
        guard let token = accessToken else {
            throw SpotifyError.notAuthenticated
        }
        
        let url = URL(string: "https://api.spotify.com/v1/audio-features/\(trackID)")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let features = try JSONDecoder().decode(AudioFeatures.self, from: data)
        
        return features
    }
    
    /// Fetch audio features for multiple tracks
    func getAudioFeaturesForTracks(trackIDs: [String]) async throws -> [AudioFeatures] {
        guard let token = accessToken else {
            throw SpotifyError.notAuthenticated
        }
        
        let ids = trackIDs.joined(separator: ",")
        let url = URL(string: "https://api.spotify.com/v1/audio-features?ids=\(ids)")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(AudioFeaturesResponse.self, from: data)
        
        return response.audio_features.compactMap { $0 }
    }
    
    // MARK: - Organize Tracks by BPM
    
    /// Organize tracks into heart rate zones based on BPM
    func organizeTracksByBPM() async throws {
        // Get track IDs
        let trackIDs = topTracks.map { $0.id }
        
        // Fetch audio features in batches (Spotify allows max 100 at a time)
        var allFeatures: [AudioFeatures] = []
        for batch in trackIDs.chunked(into: 50) {
            let features = try await getAudioFeaturesForTracks(trackIDs: batch)
            allFeatures.append(contentsOf: features)
        }
        
        // Create dictionary mapping track ID to BPM
        let bpmMap = Dictionary(uniqueKeysWithValues: allFeatures.map { ($0.id, $0.tempo) })
        
        // Organize into zones
        var zoneDict: [HeartRateZone: [SpotifyTrack]] = [:]
        
        for track in topTracks {
            guard let bpm = bpmMap[track.id] else { continue }
            let zone = HeartRateZone.from(bpm: Int(bpm))
            zoneDict[zone, default: []].append(track)
        }
        
        await MainActor.run {
            self.tracksByZone = zoneDict
        }
        
        print("✅ Organized tracks by BPM zones")
        for (zone, tracks) in zoneDict {
            print("  \(zone.rawValue): \(tracks.count) tracks")
        }
    }
    
    // MARK: - Search for Tracks by BPM
    
    /// Search for tracks within a specific BPM range
    func searchTracksByBPM(minBPM: Int, maxBPM: Int, limit: Int = 20) async throws -> [SpotifyTrack] {
        guard let token = accessToken else {
            throw SpotifyError.notAuthenticated
        }
        
        // Spotify search query
        let query = "genre:pop".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let url = URL(string: "https://api.spotify.com/v1/search?q=\(query)&type=track&limit=\(limit)")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)
        
        // Filter by BPM (need to fetch audio features)
        let trackIDs = response.tracks.items.map { $0.id }
        let features = try await getAudioFeaturesForTracks(trackIDs: trackIDs)
        
        let matchingIDs = features
            .filter { Int($0.tempo) >= minBPM && Int($0.tempo) <= maxBPM }
            .map { $0.id }
        
        let matchingTracks = response.tracks.items.filter { matchingIDs.contains($0.id) }
        
        return matchingTracks
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
struct SpotifyTrack: Codable, Identifiable {
    let id: String
    let name: String
    let artists: [Artist]
    let album: Album
    let duration_ms: Int
    let preview_url: String?
    
    var artistNames: String {
        artists.map { $0.name }.joined(separator: ", ")
    }
}

struct Artist: Codable {
    let id: String
    let name: String
}

struct Album: Codable {
    let id: String
    let name: String
    let images: [SpotifyImage]
}

struct SpotifyImage: Codable {
    let url: String
    let height: Int?
    let width: Int?
}

/// Audio features including BPM
struct AudioFeatures: Codable {
    let id: String
    let tempo: Double  // ← This is the BPM!
    let energy: Double
    let danceability: Double
    let valence: Double
    let duration_ms: Int
}

/// Heart rate zones matched to BPM
enum HeartRateZone: String {
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
}

// MARK: - API Response Models

struct TokenResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
}

struct TopTracksResponse: Codable {
    let items: [SpotifyTrack]
}

struct AudioFeaturesResponse: Codable {
    let audio_features: [AudioFeatures?]
}

struct SearchResponse: Codable {
    let tracks: TracksResponse
}

struct TracksResponse: Codable {
    let items: [SpotifyTrack]
}

// MARK: - Error Types

enum SpotifyError: Error, LocalizedError {
    case notAuthenticated
    case invalidResponse
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please log in to Spotify first"
        case .invalidResponse:
            return "Invalid response from Spotify"
        case .networkError:
            return "Network error occurred"
        }
    }
}
