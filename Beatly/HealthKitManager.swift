//
//  HealthKitManager.swift
//  Beatly
//
//  Created by Gabriel Netto on 10/04/26.
//

import Foundation
import HealthKit

/// Manages all HealthKit operations including permissions and data queries
/// This class handles reading heart rate, workout data, and user health information
@Observable
class HealthKitManager {
    
    // MARK: - Properties
    
    /// The HealthKit store - your app's gateway to health data
    private let healthStore = HKHealthStore()
    
    /// Current heart rate in BPM
    var currentHeartRate: Int = 0
    
    /// Whether HealthKit is available on this device
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    /// Authorization status
    var isAuthorized = false
    
    /// Active heart rate query (we'll keep this running while monitoring)
    private var heartRateQuery: HKQuery?
    
    // MARK: - Health Data Types
    
    /// The types of health data we want to READ
    private let typesToRead: Set<HKObjectType> = {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
              let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let workoutType = HKObjectType.workoutType() else {
            return []
        }
        
        return [heartRateType, activeEnergyType, workoutType]
    }()
    
    // MARK: - Authorization
    
    /// Request permission to access health data
    func requestAuthorization() async throws {
        // Check if HealthKit is available
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }
        
        // Request authorization
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        
        // Update authorization status
        await MainActor.run {
            isAuthorized = true
        }
    }
    
    // MARK: - Heart Rate Monitoring
    
    /// Start monitoring heart rate in real-time
    func startHeartRateMonitoring() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            print("❌ Heart rate type not available")
            return
        }
        
        // Create a query that monitors for new heart rate samples
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,  // Get all samples
            anchor: nil,     // Start from now
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            // This runs when we first start the query
            self?.processHeartRateSamples(samples)
        }
        
        // Set up the update handler - called whenever new data arrives
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHeartRateSamples(samples)
        }
        
        // Start the query
        heartRateQuery = query
        healthStore.execute(query)
        
        print("✅ Started heart rate monitoring")
    }
    
    /// Stop monitoring heart rate
    func stopHeartRateMonitoring() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
            print("⏹️ Stopped heart rate monitoring")
        }
    }
    
    /// Process heart rate samples and update the current heart rate
    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else {
            return
        }
        
        // Get the most recent sample
        guard let mostRecentSample = heartRateSamples.last else {
            return
        }
        
        // Extract BPM value
        let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
        let bpm = mostRecentSample.quantity.doubleValue(for: heartRateUnit)
        
        // Update on main thread (for UI updates)
        Task { @MainActor in
            currentHeartRate = Int(bpm)
            print("💓 Heart Rate: \(Int(bpm)) BPM")
        }
    }
    
    // MARK: - Fetch Latest Heart Rate
    
    /// Fetch the most recent heart rate sample (one-time query)
    func fetchLatestHeartRate() async throws -> Int {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.dataTypeNotAvailable
        }
        
        // Create a query to get the most recent sample
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: nil,
                limit: 1,  // Only get the most recent one
                sortDescriptors: [sortDescriptor]
            ) { query, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(throwing: HealthKitError.noData)
                    return
                }
                
                let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
                let bpm = Int(sample.quantity.doubleValue(for: heartRateUnit))
                continuation.resume(returning: bpm)
            }
            
            healthStore.execute(query)
        }
    }
}

// MARK: - Error Types

enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case dataTypeNotAvailable
    case noData
    case authorizationDenied
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .dataTypeNotAvailable:
            return "The requested health data type is not available"
        case .noData:
            return "No health data found"
        case .authorizationDenied:
            return "Authorization to access health data was denied"
        }
    }
}
