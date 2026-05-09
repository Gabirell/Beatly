//
//  YouTubeMusicManager.swift
//  Beatly
//
//  Created by Gabriel Netto on 30/04/26.
//

import Foundation

/// Manages YouTube Music integration via Google OAuth2
///
/// Setup instructions:
/// 1. Go to https://console.cloud.google.com
/// 2. Create a project → APIs & Services → Library → enable "YouTube Data API v3"
/// 3. Go to Credentials → Create Credentials → OAuth client ID → choose "iOS"
/// 4. Enter bundle ID: GabrielNetto.Beatly
/// 5. Copy the Client ID (looks like: 123456789-xxx.apps.googleusercontent.com)
/// 6. Paste it below in `clientID`
/// 7. The reversed client ID (com.googleusercontent.apps.123456789-xxx) must be added
///    as a URL scheme in Info.plist under CFBundleURLSchemes
@Observable
class YouTubeMusicManager {
    
    // MARK: - Properties
    
    /// Google OAuth Client ID — stored in Secrets.swift (git-ignored)
    private let clientID = Secrets.googleClientID
    
    /// Redirect URI uses the reversed client ID scheme that Google generates
    /// Format: com.googleusercontent.apps.{CLIENT_ID_PREFIX}:/oauthredirect
    /// When you fill in the clientID above, update this to match.
    private var redirectURI: String {
        // Extract the part before .apps.googleusercontent.com and reverse it
        let prefix = clientID.components(separatedBy: ".apps.googleusercontent.com").first ?? clientID
        return "com.googleusercontent.apps.\(prefix):/oauthredirect"
    }
    
    /// The URL scheme that needs to be in Info.plist (reversed client ID)
    var requiredURLScheme: String {
        let prefix = clientID.components(separatedBy: ".apps.googleusercontent.com").first ?? clientID
        return "com.googleusercontent.apps.\(prefix)"
    }
    
    /// Whether credentials have been configured
    var isConfigured: Bool {
        clientID != "YOUR_GOOGLE_CLIENT_ID" && !clientID.isEmpty
    }
    
    /// OAuth access token
    var accessToken: String?
    
    /// Whether user is authenticated
    var isAuthenticated: Bool {
        accessToken != nil
    }
    
    /// User's display name
    var userName: String?
    
    /// Status text for profile display
    var statusText: String {
        if !isConfigured {
            return "Needs setup — see docs"
        }
        if isAuthenticated {
            return "Connected as \(userName ?? "User")"
        }
        return "Not connected"
    }
    
    // MARK: - Authentication
    
    /// Get the authorization URL to open in system browser
    func getAuthorizationURL() -> URL? {
        guard isConfigured else {
            print("⚠️ YouTube Music: clientID not configured. See setup instructions in YouTubeMusicManager.swift")
            return nil
        }
        
        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "https://www.googleapis.com/auth/youtube.readonly"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]
        
        return components.url
    }
    
    /// Exchange authorization code for access token
    func exchangeCodeForToken(code: String) async throws {
        guard let url = URL(string: "https://oauth2.googleapis.com/token") else {
            throw YouTubeMusicError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Note: iOS OAuth clients are "public" clients — no client_secret needed
        let params = [
            "code": code,
            "client_id": clientID,
            "redirect_uri": redirectURI,
            "grant_type": "authorization_code"
        ]
        
        let bodyString = params
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
        
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let bodyStr = String(data: data, encoding: .utf8) ?? "no body"
            print("❌ YouTube Music token error: \(bodyStr)")
            throw YouTubeMusicError.authenticationFailed
        }
        
        let tokenResponse = try JSONDecoder().decode(GoogleTokenResponse.self, from: data)
        
        await MainActor.run {
            self.accessToken = tokenResponse.access_token
        }
        
        // Fetch user profile
        try await fetchUserProfile()
        
        print("✅ YouTube Music authenticated: \(userName ?? "unknown")")
    }
    
    /// Fetch the user's YouTube channel name
    private func fetchUserProfile() async throws {
        guard let token = accessToken,
              let url = URL(string: "https://www.googleapis.com/youtube/v3/channels?part=snippet&mine=true") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let items = json["items"] as? [[String: Any]],
           let snippet = items.first?["snippet"] as? [String: Any],
           let title = snippet["title"] as? String {
            await MainActor.run {
                self.userName = title
            }
        }
    }
    
    /// Disconnect from YouTube Music
    func disconnect() {
        accessToken = nil
        userName = nil
    }
}

// MARK: - Data Models

struct GoogleTokenResponse: Codable {
    let access_token: String
    let token_type: String?
    let expires_in: Int?
    let refresh_token: String?
}

// MARK: - Error Types

enum YouTubeMusicError: Error, LocalizedError {
    case notAuthenticated
    case networkError
    case authenticationFailed
    case notConfigured
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please log in to YouTube Music first"
        case .networkError:
            return "Network error occurred"
        case .authenticationFailed:
            return "YouTube Music authentication failed"
        case .notConfigured:
            return "YouTube Music credentials not configured"
        }
    }
}
