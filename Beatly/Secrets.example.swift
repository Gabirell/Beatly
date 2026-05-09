//
//  Secrets.example.swift
//  Beatly
//
//  TEMPLATE — Copy this file to Secrets.swift and fill in your keys.
//  Secrets.swift is git-ignored so your keys stay private.
//
//  Steps:
//  1. Duplicate this file: cp Secrets.example.swift Secrets.swift
//  2. Rename SecretsTemplate → Secrets in the copy
//  3. Fill in your API credentials below
//  4. Secrets.swift will NOT be committed to git
//

import Foundation

/// Template enum — rename to `Secrets` when you create your own copy.
/// This file compiles alongside Secrets.swift without conflict.
enum SecretsTemplate {

    // MARK: - Spotify
    // Register at https://developer.spotify.com/dashboard

    static let spotifyClientID = ""
    static let spotifyClientSecret = ""
    static let spotifyRedirectURI = "beatly://callback"

    // MARK: - Strava
    // Register at https://www.strava.com/settings/api
    // Set "Authorization Callback Domain" to: strava-callback

    static let stravaClientID = ""
    static let stravaClientSecret = ""
    static let stravaRedirectURI = "beatly://strava-callback"

    // MARK: - YouTube Music (Google OAuth)
    // Register at https://console.cloud.google.com
    // Enable YouTube Data API v3, create iOS OAuth client ID
    // Enter bundle ID: GabrielNetto.Beatly
    // Also add the reversed client ID as a URL scheme in Info.plist

    static let googleClientID = ""

    // MARK: - Deezer
    // Register at https://developers.deezer.com/myapps

    static let deezerAppID = ""
    static let deezerSecretKey = ""
    static let deezerRedirectURI = "beatly://deezer-callback"
}
