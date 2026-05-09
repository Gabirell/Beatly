//
//  MusicKitManager.swift
//  Beatly
//
//  Created by Gabriel Netto on 30/04/26.
//

import Foundation
import MusicKit

/// Manages Apple Music authorization via MusicKit
@Observable
class MusicKitManager {
    
    // MARK: - Properties
    
    /// Current authorization status
    var authorizationStatus: MusicAuthorization.Status = .notDetermined
    
    /// Whether Apple Music is authorized
    var isAuthorized: Bool {
        authorizationStatus == .authorized
    }
    
    /// Human-readable status text
    var statusText: String {
        switch authorizationStatus {
        case .authorized:
            return "Authorized"
        case .denied:
            return "Denied — check Settings"
        case .restricted:
            return "Restricted"
        case .notDetermined:
            return "Not authorized"
        @unknown default:
            return "Unknown"
        }
    }
    
    // MARK: - Init
    
    init() {
        authorizationStatus = MusicAuthorization.currentStatus
    }
    
    // MARK: - Methods
    
    /// Request Apple Music authorization
    func requestAuthorization() async {
        let status = await MusicAuthorization.request()
        await MainActor.run {
            authorizationStatus = status
        }
    }
}
