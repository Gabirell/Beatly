//
//  SpotifyLoginView.swift
//  Beatly
//
//  Created by Gabriel Netto on 10/04/26.
//

import SwiftUI

/// View for authenticating with Spotify
struct SpotifyLoginView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(SpotifyManager.self) private var manager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                // Music Logo
                Image(systemName: "music.note.list")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                
                // Title
                VStack(spacing: 8) {
                    Text("Connect Your Music")
                        .font(.title.bold())
                    
                    Text("Sync your music with your workout intensity")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Features List
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(
                        icon: "heart.fill",
                        title: "Match Music to Heart Rate",
                        description: "Songs automatically adjust to your workout intensity"
                    )
                    
                    FeatureRow(
                        icon: "music.note",
                        title: "Organize by BPM",
                        description: "Your music sorted into workout zones"
                    )
                    
                    FeatureRow(
                        icon: "sparkles",
                        title: "Discover New Music",
                        description: "Find songs perfect for your pace"
                    )
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                Spacer()
                
                // Login Buttons
                VStack(spacing: 12) {
                    Button {
                        if let url = manager.getAuthorizationURL() {
                            print("🔗 Opening Spotify auth URL...")
                            dismiss()
                            // Open URL after sheet dismisses to avoid conflicts
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                UIApplication.shared.open(url)
                            }
                        } else {
                            print("❌ getAuthorizationURL() returned nil")
                        }
                    } label: {
                        HStack {
                            Image(systemName: "music.note")
                            Text("Connect with Spotify")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green.gradient, in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button {
                        // TODO: Apple Music integration
                    } label: {
                        HStack {
                            Image(systemName: "apple.logo")
                            Text("Connect with Apple Music")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.pink.gradient, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                
                Button("Cancel") {
                    dismiss()
                }
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// Feature row for login screen
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.green)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    SpotifyLoginView()
        .environment(SpotifyManager())
}
