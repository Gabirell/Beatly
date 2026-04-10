//
//  PlaylistView.swift
//  Beatly
//
//  Created by Gabriel Netto on 10/04/26.
//

import SwiftUI

/// PlaylistView manages music playlists organized by BPM
/// Users can browse their music and discover new tracks
struct PlaylistView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Section: My Music
                    VStack(alignment: .leading, spacing: 12) {
                        Text("My Music")
                            .font(.title2.bold())
                            .padding(.horizontal)
                        
                        // Placeholder for user's music organized by BPM
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                PlaylistCardPlaceholder(title: "Slow Warm-up", bpm: "60-90")
                                PlaylistCardPlaceholder(title: "Steady Pace", bpm: "90-120")
                                PlaylistCardPlaceholder(title: "High Intensity", bpm: "120-160")
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Section: Discover
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Discover")
                            .font(.title2.bold())
                            .padding(.horizontal)
                        
                        // Placeholder for recommended music
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                PlaylistCardPlaceholder(title: "Recommended", bpm: "Various")
                                PlaylistCardPlaceholder(title: "Similar Style", bpm: "Various")
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .navigationTitle("Playlists")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Action to create new playlist
                        print("Create new playlist")
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
    }
}

/// Placeholder card for playlists
struct PlaylistCardPlaceholder: View {
    let title: String
    let bpm: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Album art placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(.blue.gradient)
                .frame(width: 160, height: 160)
                .overlay {
                    Image(systemName: "music.note")
                        .font(.system(size: 50))
                        .foregroundStyle(.white.opacity(0.8))
                }
            
            Text(title)
                .font(.headline)
            
            Text("\(bpm) BPM")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 160)
    }
}

#Preview {
    PlaylistView()
}
