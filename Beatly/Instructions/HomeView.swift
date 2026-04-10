//
//  HomeView.swift
//  Beatly
//
//  Created by Gabriel Netto on 10/04/26.
//

import SwiftUI

/// HomeView displays the main screen with real-time heart rate
/// This is where the pulsing heart animation will appear
struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                // Placeholder for the pulsing heart
                // We'll add animation and real data later
                ZStack {
                    Circle()
                        .fill(.red.gradient)
                        .frame(width: 200, height: 200)
                    
                    Image(systemName: "headphones")
                        .font(.system(size: 60))
                        .foregroundStyle(.white)
                }
                
                // Placeholder BPM display
                VStack(spacing: 8) {
                    Text("-- BPM")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    
                    Text("Heart Rate")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Quick stats section (we'll add real data later)
                HStack(spacing: 40) {
                    StatView(title: "Calories", value: "--")
                    StatView(title: "Duration", value: "--")
                    StatView(title: "Zone", value: "--")
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Beatly")
        }
    }
}

/// A reusable component for displaying statistics
struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HomeView()
}
