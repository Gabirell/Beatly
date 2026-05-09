//
//  StravaManager.swift
//  Beatly
//
//  Created by Gabriel Netto on 30/04/26.
//

import Foundation

/// Manages Strava API interactions via OAuth2
/// Register your app at https://www.strava.com/settings/api to get credentials
@Observable
class StravaManager {
    
    // MARK: - Properties
    
    /// Strava credentials — stored in Secrets.swift (git-ignored)
    private let clientID = Secrets.stravaClientID
    private let clientSecret = Secrets.stravaClientSecret
    private let redirectURI = Secrets.stravaRedirectURI
    
    /// OAuth access token
    var accessToken: String?
    
    /// Whether user is authenticated with Strava
    var isAuthenticated: Bool {
        accessToken != nil
    }
    
    /// Athlete name from profile
    var athleteName: String?
    
    // MARK: - Authentication
    
    /// Get the authorization URL for Strava login
    func getAuthorizationURL() -> URL? {
        var components = URLComponents(string: "https://www.strava.com/oauth/authorize")!
        
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "approval_prompt", value: "auto"),
            URLQueryItem(name: "scope", value: "read,activity:read")
        ]
        
        return components.url
    }
    
    /// Exchange authorization code for access token
    func exchangeCodeForToken(code: String) async throws {
        guard let url = URL(string: "https://www.strava.com/api/v3/oauth/token") else {
            throw StravaError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "client_id": clientID,
            "client_secret": clientSecret,
            "code": code,
            "grant_type": "authorization_code"
        ]
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? "no body"
            print("❌ Strava token error: \(bodyString)")
            throw StravaError.authenticationFailed
        }
        
        let tokenResponse = try JSONDecoder().decode(StravaTokenResponse.self, from: data)
        
        await MainActor.run {
            self.accessToken = tokenResponse.access_token
            self.athleteName = "\(tokenResponse.athlete?.firstname ?? "") \(tokenResponse.athlete?.lastname ?? "")".trimmingCharacters(in: .whitespaces)
        }
        
        print("✅ Strava authenticated: \(athleteName ?? "unknown")")
    }
    
    /// Disconnect from Strava
    func disconnect() {
        accessToken = nil
        athleteName = nil
    }
}

// MARK: - Data Models

struct StravaTokenResponse: Codable {
    let access_token: String
    let token_type: String?
    let expires_at: Int?
    let athlete: StravaAthlete?
}

struct StravaAthlete: Codable {
    let id: Int?
    let firstname: String?
    let lastname: String?
}

// MARK: - Error Types

enum StravaError: Error, LocalizedError {
    case notAuthenticated
    case networkError
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please log in to Strava first"
        case .networkError:
            return "Network error occurred"
        case .authenticationFailed:
            return "Strava authentication failed"
        }
    }
}
