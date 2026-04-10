//
//  ProfileView.swift
//  Beatly
//
//  Created by Gabriel Netto on 10/04/26.
//

import SwiftUI

/// ProfileView displays user settings and preferences
/// Includes Spotify connection, health data, and app settings
struct ProfileView: View {
    var body: some View {
        NavigationStack {
            List {
                // User Info Section
                Section {
                    HStack(spacing: 16) {
                        // Profile picture placeholder
                        Circle()
                            .fill(.purple.gradient)
                            .frame(width: 60, height: 60)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.title)
                                    .foregroundStyle(.white)
                            }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome!")
                                .font(.title3.bold())
                            Text("Setup your profile")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Connections Section
                Section("Connections") {
                    SettingsRow(
                        icon: "music.note",
                        iconColor: .green,
                        title: "Spotify",
                        subtitle: "Not connected"
                    )
                    
                    SettingsRow(
                        icon: "heart.fill",
                        iconColor: .red,
                        title: "Health Data",
                        subtitle: "Not connected"
                    )
                    
                    SettingsRow(
                        icon: "location.fill",
                        iconColor: .blue,
                        title: "Location Services",
                        subtitle: "Not enabled"
                    )
                }
                
                // Health Info Section
                Section("Health Information") {
                    SettingsRow(
                        icon: "figure.stand",
                        iconColor: .orange,
                        title: "Body Metrics",
                        subtitle: "Height, Weight, Age"
                    )
                    
                    SettingsRow(
                        icon: "heart.text.square",
                        iconColor: .pink,
                        title: "Health Goals",
                        subtitle: "Set your fitness targets"
                    )
                }
                
                // Social Features Section
                Section("Social") {
                    SettingsRow(
                        icon: "person.2.fill",
                        iconColor: .indigo,
                        title: "Friends",
                        subtitle: "Share workouts and compete"
                    )
                    
                    SettingsRow(
                        icon: "trophy.fill",
                        iconColor: .yellow,
                        title: "Leaderboard",
                        subtitle: "View your rankings"
                    )
                }
                
                // App Settings Section
                Section("Settings") {
                    SettingsRow(
                        icon: "bell.fill",
                        iconColor: .blue,
                        title: "Notifications",
                        subtitle: "Manage alerts"
                    )
                    
                    SettingsRow(
                        icon: "shield.fill",
                        iconColor: .green,
                        title: "Privacy & Safety",
                        subtitle: "Location sharing and alerts"
                    )
                }
            }
            .navigationTitle("Profile")
        }
    }
}

/// Reusable row for settings
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            RoundedRectangle(cornerRadius: 6)
                .fill(iconColor.gradient)
                .frame(width: 32, height: 32)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    ProfileView()
}
