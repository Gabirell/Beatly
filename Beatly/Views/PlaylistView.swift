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
    @Environment(SpotifyManager.self) private var spotifyManager
    @Environment(PlaybackManager.self) private var playbackManager
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Group {
                    if spotifyManager.isAuthenticated {
                        authenticatedView
                    } else {
                        unauthenticatedView
                    }
                }
                
                // Now Playing bar
                if playbackManager.currentTrack != nil {
                    NowPlayingBar()
                }
            }
            .navigationTitle("Playlists")
            .toolbar {
                if spotifyManager.isAuthenticated {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task {
                                await loadSpotifyData()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    // MARK: - Authenticated View
    
    private var authenticatedView: some View {
        Group {
            if isLoading {
                ProgressView("Loading your music...")
            } else if spotifyManager.tracksByZone.isEmpty {
                emptyStateView
            } else {
                playlistsView
            }
        }
    }
    
    // MARK: - Playlists View
    
    private var playlistsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary Card
                VStack(spacing: 12) {
                    Text("\(spotifyManager.topTracks.count) Songs")
                        .font(.title.bold())
                    Text("Organized by workout intensity")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                // Zones
                ForEach(HeartRateZone.allCases, id: \.self) { zone in
                    if let tracks = spotifyManager.tracksByZone[zone], !tracks.isEmpty {
                        ZoneSection(zone: zone, tracks: tracks)
                    }
                }
                
                // Spacer for now-playing bar
                if playbackManager.currentTrack != nil {
                    Spacer().frame(height: 80)
                }
            }
            .padding(.top)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Music Yet")
                .font(.title2.bold())
            
            Text("Tap the refresh button to load your Spotify music")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                Task {
                    await loadSpotifyData()
                }
            } label: {
                Label("Load My Music", systemImage: "arrow.down.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .background(.green.gradient, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
    
    // MARK: - Unauthenticated View
    
    private var unauthenticatedView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "music.note.list")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            
            VStack(spacing: 8) {
                Text("Connect Your Music")
                    .font(.title.bold())
                
                Text("Match your music to your workout intensity")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Button {
                    if let url = spotifyManager.getAuthorizationURL() {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Connect with Spotify", systemImage: "music.note")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green.gradient, in: RoundedRectangle(cornerRadius: 12))
                }
                
                Button {
                    // TODO: Apple Music integration
                } label: {
                    Label("Connect with Apple Music", systemImage: "apple.logo")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.pink.gradient, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Methods
    
    private func loadSpotifyData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch top tracks
            try await spotifyManager.fetchTopTracks()
            
            // Organize by BPM
            try await spotifyManager.organizeTracksByBPM()
            
            isLoading = false
        } catch {
            isLoading = false
            let debug = spotifyManager.debugResponse ?? "none"
            errorMessage = "\(error.localizedDescription)\n\nAPI response:\n\(debug)"
        }
    }
}

// MARK: - Zone Section

struct ZoneSection: View {
    let zone: HeartRateZone
    let tracks: [SpotifyTrack]
    @Environment(PlaybackManager.self) private var playbackManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Zone Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(zone.rawValue)
                        .font(.title3.bold())
                    
                    Text("\(zone.bpmRange.lowerBound)-\(zone.bpmRange.upperBound) BPM")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Play zone button
                Button {
                    playbackManager.playQueue(tracks: tracks)
                } label: {
                    Image(systemName: "play.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(zone.color.gradient, in: Circle())
                }
                
                Text("\(tracks.count)")
                    .font(.title2.bold())
                    .foregroundStyle(zone.color)
            }
            .padding(.horizontal)
            
            // Tracks
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(tracks.prefix(10)) { track in
                        TrackCard(track: track, color: zone.color)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Track Card

struct TrackCard: View {
    let track: SpotifyTrack
    let color: Color
    @Environment(PlaybackManager.self) private var playbackManager
    
    private var isCurrentlyPlaying: Bool {
        playbackManager.isCurrentTrack(track) && playbackManager.isPlaying
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Album Art with Play Button overlay
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .overlay {
                        if let imageURL = track.album?.images?.first?.url,
                           let url = URL(string: imageURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "music.note")
                                    .font(.title)
                                    .foregroundStyle(.white)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Image(systemName: "music.note")
                                .font(.title)
                                .foregroundStyle(.white)
                        }
                    }
                
                // Play/Pause overlay button
                Button {
                    playbackManager.togglePlayPause(track: track)
                } label: {
                    Circle()
                        .fill(.black.opacity(0.5))
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: isCurrentlyPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                                .offset(x: isCurrentlyPlaying ? 0 : 2)
                        }
                }
            }
            .frame(width: 120, height: 120)
            
            // Track Info
            VStack(alignment: .leading, spacing: 2) {
                Text(track.name)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .foregroundStyle(playbackManager.isCurrentTrack(track) ? color : .primary)
                
                Text(track.artistNames)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 120)
        }
    }
}

// MARK: - Now Playing Bar

struct NowPlayingBar: View {
    @Environment(PlaybackManager.self) private var playbackManager
    
    var body: some View {
        if let track = playbackManager.currentTrack {
            VStack(spacing: 0) {
                // Progress bar
                GeometryReader { geo in
                    Rectangle()
                        .fill(.green)
                        .frame(width: geo.size.width * playbackManager.playbackProgress, height: 2)
                }
                .frame(height: 2)
                
                HStack(spacing: 12) {
                    // Album art thumbnail
                    if let imageURL = track.album?.images?.first?.url,
                       let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.green.opacity(0.3))
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    
                    // Track info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.name)
                            .font(.caption.bold())
                            .lineLimit(1)
                        HStack(spacing: 4) {
                            Text(track.artistNames)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            if playbackManager.isQueueMode {
                                Text("•")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(playbackManager.queuePositionText)
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Preview label
                    if playbackManager.playbackMode == .preview && !playbackManager.isQueueMode {
                        Text("Preview")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    
                    // Previous track button (queue mode)
                    if playbackManager.isQueueMode {
                        Button {
                            playbackManager.playPrevious()
                        } label: {
                            Image(systemName: "backward.fill")
                                .font(.caption)
                                .frame(width: 28, height: 28)
                        }
                        .disabled(!playbackManager.hasPrevious)
                    }
                    
                    // Play/Pause button
                    Button {
                        if playbackManager.isPlaying {
                            playbackManager.pause()
                        } else {
                            playbackManager.resume()
                        }
                    } label: {
                        Image(systemName: playbackManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title3)
                            .frame(width: 36, height: 36)
                    }
                    
                    // Next track button (queue mode)
                    if playbackManager.isQueueMode {
                        Button {
                            playbackManager.playNext()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.caption)
                                .frame(width: 28, height: 28)
                        }
                        .disabled(!playbackManager.hasNext)
                    }
                    
                    // Stop button
                    Button {
                        playbackManager.stop()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 28)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(.ultraThinMaterial)
        }
    }
}

#Preview {
    PlaylistView()
        .environment(SpotifyManager())
        .environment(PlaybackManager())
}
