//
//  HomeView.swift
//  Beatly
//
//  Created by Gabriel Netto on 10/04/26.
//

import SwiftUI

/// HomeView displays the main screen with real-time heart rate
/// Features a pulsing heart animation that syncs with BPM
struct HomeView: View {
    // MARK: - State Variables
    
    /// HealthKit manager for accessing heart rate data
    @Environment(HealthKitManager.self) private var healthManager
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    
    /// Current heart rate (from HealthKit or simulated)
    @State private var currentBPM = 72
    
    /// Controls whether we're using real HealthKit data or demo mode
    @State private var useRealData = false
    
    /// Controls whether we're simulating an active workout
    @State private var isWorkoutActive = false
    
    /// Simulated workout stats
    @State private var calories = 0
    @State private var workoutDuration = 0
    
    /// Timer for simulating heart rate changes
    @State private var timer: Timer?
    
    /// Show permission alert
    @State private var showPermissionAlert = false
    @State private var permissionError: String?
    
    // MARK: - Computed Properties
    
    /// Determines heart color based on BPM zones
    var heartColor: Color {
        switch currentBPM {
        case 0..<60: return .blue       // Resting/Low
        case 60..<100: return .green    // Normal resting
        case 100..<140: return .orange  // Moderate exercise
        case 140..<170: return .red     // Intense exercise
        default: return .purple         // Maximum effort
        }
    }
     
    /// Returns the zone name based on BPM
    var heartZone: String {
        switch currentBPM {
        case 0..<60: return "Resting"
        case 60..<100: return "Normal"
        case 100..<140: return "Cardio"
        case 140..<170: return "Intense"
        default: return "Maximum"
        }
    }
    
    /// Animation speed based on BPM (faster pulse = higher BPM)
    var pulseSpeed: Double {
        // Convert BPM to animation duration
        // 60 BPM = 1 beat per second
        // Formula: 60 / BPM = seconds per beat
        return 60.0 / Double(currentBPM)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                // MARK: Pulsing Heart Logo
                HeartLogoView(
                    zoneColor: heartColor,
                    pulseSpeed: pulseSpeed
                )
                
                // MARK: BPM Display
                VStack(spacing: 8) {
                    Text("\(currentBPM) BPM")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(heartColor)
                        .contentTransition(.numericText())
                    
                    Text("Heart Rate")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // MARK: Quick Stats Section
                HStack(spacing: 40) {
                    StatView(
                        title: "Calories", 
                        value: "\(calories)",
                        color: .orange
                    )
                    StatView(
                        title: "Duration", 
                        value: formatDuration(workoutDuration),
                        color: .blue
                    )
                    StatView(
                        title: "Zone", 
                        value: heartZone,
                        color: heartColor
                    )
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                // MARK: Control Buttons
                VStack(spacing: 12) {
                    // HealthKit Toggle
                    if healthManager.isAvailable {
                        Button {
                            toggleHealthKit()
                        } label: {
                            Label(
                                useRealData ? "Using Real Data" : "Use HealthKit",
                                systemImage: useRealData ? "heart.circle.fill" : "heart.circle"
                            )
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                useRealData ? Color.pink.gradient : Color.blue.gradient,
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                        }
                    }
                    
                    // Demo Mode Button
                    Button {
                        toggleWorkout()
                    } label: {
                        Label(
                            isWorkoutActive ? "Stop Demo" : "Start Demo",
                            systemImage: isWorkoutActive ? "stop.fill" : "play.fill"
                        )
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            isWorkoutActive ? Color.red.gradient : Color.green.gradient,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                    }
                    .disabled(useRealData)  // Disable demo when using real data
                }
                .padding(.horizontal)
                .padding(.bottom, 45)  // Add extra space above tab bar
                
                Spacer()
                    .frame(height: 1)  // Minimal spacer to prevent over-compression
            }
            .background(
                LinearGradient(
                    colors: themeManager.currentTheme.backgroundGradient(for: colorScheme),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Beatly")
            .alert("HealthKit Permission", isPresented: $showPermissionAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                if let error = permissionError {
                    Text(error)
                } else {
                    Text("HealthKit access granted! Your real heart rate will now be displayed.")
                }
            }
            .onChange(of: healthManager.currentHeartRate) { oldValue, newValue in
                // Update BPM when HealthKit data changes
                if useRealData && newValue > 0 {
                    withAnimation {
                        currentBPM = newValue
                    }
                }
            }
        }
    }
    
    // MARK: - Methods
    
    /// Toggles HealthKit on/off
    private func toggleHealthKit() {
        if useRealData {
            // Turn off HealthKit
            healthManager.stopHeartRateMonitoring()
            useRealData = false
            currentBPM = 72  // Return to default
        } else {
            // Turn on HealthKit
            Task {
                do {
                    // Request authorization
                    if !healthManager.isAuthorized {
                        try await healthManager.requestAuthorization()
                    }
                    
                    // Start monitoring
                    await MainActor.run {
                        healthManager.startHeartRateMonitoring()
                        useRealData = true
                        showPermissionAlert = true
                        permissionError = nil
                    }
                    
                    // Try to fetch initial value
                    if let latestHR = try? await healthManager.fetchLatestHeartRate() {
                        await MainActor.run {
                            currentBPM = latestHR
                        }
                    }
                } catch {
                    await MainActor.run {
                        permissionError = error.localizedDescription
                        showPermissionAlert = true
                    }
                }
            }
        }
    }
    
    /// Toggles the simulated workout on/off
    private func toggleWorkout() {
        isWorkoutActive.toggle()
        
        if isWorkoutActive {
            startSimulation()
        } else {
            stopSimulation()
        }
    }
    
    /// Starts simulating workout data
    private func startSimulation() {
        // Reset stats
        calories = 0
        workoutDuration = 0
        
        // Start timer to simulate changing heart rate
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                // Simulate heart rate fluctuation during workout
                currentBPM = Int.random(in: 100...160)
                
                // Increment workout stats
                workoutDuration += 2
                calories += Int.random(in: 1...3)
            }
        }
    }
    
    /// Stops the simulation
    private func stopSimulation() {
        timer?.invalidate()
        timer = nil
        
        // Return to resting heart rate
        withAnimation(.easeInOut(duration: 2.0)) {
            currentBPM = 72
        }
    }
    
    /// Formats seconds into MM:SS format
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

/// A reusable component for displaying statistics
struct StatView: View {
    let title: String
    let value: String
    var color: Color = .primary
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HomeView()
        .environment(HealthKitManager())
        .environment(ThemeManager())
}
