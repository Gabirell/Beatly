//
//  WorkoutView.swift
//  Beatly
//
//  Created by Gabriel Netto on 10/04/26.
//

import SwiftUI

/// WorkoutView allows users to plan and track exercise sessions
/// Users can create effort routines with different intensity phases
struct WorkoutView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Workout Status
                    VStack(spacing: 12) {
                        Text("No Active Workout")
                            .font(.title3.bold())
                        
                        Button {
                            // Action to start a workout
                            print("Start workout")
                        } label: {
                            Label("Start Workout", systemImage: "play.fill")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.green.gradient, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    
                    Divider()
                    
                    // Saved Workout Plans
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("My Workout Plans")
                                .font(.title2.bold())
                            
                            Spacer()
                            
                            Button {
                                // Action to create new plan
                                print("Create new workout plan")
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Placeholder workout plans
                        VStack(spacing: 12) {
                            WorkoutPlanCard(
                                title: "Morning Cardio",
                                duration: "30 min",
                                phases: 3
                            )
                            
                            WorkoutPlanCard(
                                title: "HIIT Session",
                                duration: "20 min",
                                phases: 5
                            )
                            
                            WorkoutPlanCard(
                                title: "Long Run",
                                duration: "60 min",
                                phases: 4
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Workout")
        }
    }
}

/// Card displaying a workout plan
struct WorkoutPlanCard: View {
    let title: String
    let duration: String
    let phases: Int
    
    var body: some View {
        HStack {
            // Icon
            RoundedRectangle(cornerRadius: 8)
                .fill(.orange.gradient)
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "figure.run")
                        .foregroundStyle(.white)
                }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                HStack {
                    Label(duration, systemImage: "clock")
                    Text("•")
                    Label("\(phases) phases", systemImage: "chart.bar.fill")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Action button
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    WorkoutView()
}
