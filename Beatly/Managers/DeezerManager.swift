//
//  DeezerManager.swift
//  Beatly
//
//  Created by Gabriel Netto on 30/04/26.
//

import Foundation

/// Manages Deezer integration via OAuth2
/// Register at https://developers.deezer.com/myapps to get credentials
@Observable
class DeezerManager {
    
    // MARK: - Properties
    
    /// Deezer credentials — stored in Secrets.swift (git-ignored)
    private let appID = Secrets.deezerAppID
    private let secretKey = Secrets.deezerSecretKey
    private let redirectURI = Secrets.deezerRedirectURI
    
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
        if isAuthenticated {
            return "Connected as \(userName ?? "User")"
        }
        return "Not connected"
    }
    
    // MARK: - Authentication
    
    /// Get the authorization URL to open in system browser
    func getAuthorizationURL() -> URL? {
        var components = URLComponents(string: "https://connect.deezer.com/oauth/auth.php")!
        
        components.queryItems = [
            URLQueryItem(name: "app_id", value: appID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "perms", value: "basic_access,listening_history")
        ]
        
        return components.url
    }
    
    /// Exchange authorization code for access token
    func exchangeCodeForToken(code: String) async throws {
        var components = URLComponents(string: "https://connect.deezer.com/oauth/access_token.php")!
        
        components.queryItems = [
            URLQueryItem(name: "app_id", value: appID),
            URLQueryItem(name: "secret", value: secretKey),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "output", value: "json")
        ]
        
        guard let url = components.url else {
            throw DeezerError.networkError
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let bodyStr = String(data: data, encoding: .utf8) ?? "no body"
            print("❌ Deezer token error: \(bodyStr)")
            throw DeezerError.authenticationFailed
        }
        
        let tokenResponse = try JSONDecoder().decode(DeezerTokenResponse.self, from: data)
        
        await MainActor.run {
            self.accessToken = tokenResponse.access_token
        }
        
        // Fetch user profile
        try await fetchUserProfile()
        
        print("✅ Deezer authenticated: \(userName ?? "unknown")")
    }
    
    /// Fetch the user's Deezer profile name
    private func fetchUserProfile() async throws {
        guard let token = accessToken,
              let url = URL(string: "https://api.deezer.com/user/me?access_token=\(token)") else { return }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let name = json["name"] as? String {
            await MainActor.run {
                self.userName = name
            }
        }
    }
    
    /// Disconnect from Deezer
    func disconnect() {
        accessToken = nil
        userName = nil
    }
}

// MARK: - Data Models

struct DeezerTokenResponse: Codable {
    let access_token: String
    let expires: Int?
}

// MARK: - Error Types

enum DeezerError: Error, LocalizedError {
    case notAuthenticated
    case networkError
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please log in to Deezer first"
        case .networkError:
            return "Network error occurred"
        case .authenticationFailed:
            return "Deezer authentication failed"
        }
    }
}
