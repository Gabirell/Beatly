//
//  LocationManager.swift
//  Beatly
//
//  Created by Gabriel Netto on 30/04/26.
//

import Foundation
import CoreLocation

/// Manages location services authorization and tracking
@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    
    // MARK: - Properties
    
    private let manager = CLLocationManager()
    
    /// Current authorization status
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    /// Whether location services are authorized
    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    /// Human-readable status text
    var statusText: String {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return "Enabled"
        case .denied:
            return "Denied — check Settings"
        case .restricted:
            return "Restricted"
        case .notDetermined:
            return "Not enabled"
        @unknown default:
            return "Unknown"
        }
    }
    
    // MARK: - Init
    
    override init() {
        super.init()
        manager.delegate = self
        authorizationStatus = manager.authorizationStatus
    }
    
    // MARK: - Methods
    
    /// Request when-in-use location permission
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}
