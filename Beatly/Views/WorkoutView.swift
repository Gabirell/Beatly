//
//  WorkoutView.swift
//  Beatly
//
//  Created by Gabriel Netto on 10/04/26.
//

import SwiftUI

/// WorkoutView allows users to create custom workout playlists with BPM zone sequences
struct WorkoutView: View {
    @Environment(WorkoutPlaylistManager.self) private var playlistManager
    @Environment(SpotifyManager.self) private var spotifyManager
    @Environment(PlaybackManager.self) private var playbackManager
    @Environment(HealthKitManager.self) private var healthKitManager
    
    @State private var showingCreateSheet = false
    @State private var editingPlaylist: WorkoutPlaylist?
    
    private var hasMusic: Bool {
        !spotifyManager.tracksByZone.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                mainContent
                
                if playbackManager.currentTrack != nil {
                    NowPlayingBar()
                }
            }
            .navigationTitle("Workout")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateWorkoutPlaylistView()
            }
            .sheet(item: $editingPlaylist) { playlist in
                EditWorkoutPlaylistView(playlist: playlist)
            }
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        List {
            // Auto DJ Section
            Section {
                AutoDJCard()
            } header: {
                Text("Auto DJ")
            }
            
            // Playlists section
            Section {
                ForEach(playlistManager.playlists) { playlist in
                    WorkoutPlaylistRow(
                        playlist: playlist,
                        onEdit: { editingPlaylist = playlist },
                        onRandomize: {
                            playlistManager.randomizeTracks(for: playlist.id, tracksByZone: spotifyManager.tracksByZone)
                        },
                        onPlay: {
                            let tracks = playlist.allTracks
                            if !tracks.isEmpty {
                                playbackManager.playQueue(tracks: tracks)
                            }
                        }
                    )
                }
                .onDelete { offsets in
                    playlistManager.deletePlaylists(at: offsets)
                }
                .onMove { source, destination in
                    playlistManager.movePlaylists(from: source, to: destination)
                }
            } header: {
                Text("My Workout Playlists")
            }
            
            // Spacer for now-playing bar
            if playbackManager.currentTrack != nil {
                Spacer().frame(height: 80)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Auto DJ Card

struct AutoDJCard: View {
    @Environment(PlaybackManager.self) private var playbackManager
    @Environment(SpotifyManager.self) private var spotifyManager
    @Environment(HealthKitManager.self) private var healthKitManager
    
    private var hasMusic: Bool {
        !spotifyManager.tracksByZone.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .font(.title2)
                    .foregroundStyle(.pink)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Heart Rate DJ")
                        .font(.headline)
                    Text("Music adapts to your heart rate in real-time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            if playbackManager.isAutoDJActive {
                // Active state
                VStack(spacing: 8) {
                    HStack {
                        // Current heart rate
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                            Text("\(healthKitManager.currentHeartRate) BPM")
                                .font(.subheadline.bold())
                        }
                        
                        Spacer()
                        
                        // Current zone
                        if let zone = playbackManager.autoDJCurrentZone {
                            Text(zone.rawValue)
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(zone.color.gradient, in: Capsule())
                        }
                        
                        Spacer()
                        
                        // Tracks played count
                        Text("\(playbackManager.autoDJTracksPlayed) played")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Button {
                        playbackManager.stopAutoDJ()
                    } label: {
                        Label("Stop Auto DJ", systemImage: "stop.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(.red.gradient, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                // Inactive state
                if !hasMusic {
                    Text("Load your music from the Playlists tab first")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Button {
                        playbackManager.startAutoDJ(
                            tracksByZone: spotifyManager.tracksByZone,
                            heartRateProvider: { healthKitManager.currentHeartRate }
                        )
                    } label: {
                        Label("Start Auto DJ", systemImage: "play.fill")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(.pink.gradient, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Workout Playlist Row

struct WorkoutPlaylistRow: View {
    let playlist: WorkoutPlaylist
    let onEdit: () -> Void
    let onRandomize: () -> Void
    let onPlay: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title & Duration
            HStack {
                Text(playlist.name)
                    .font(.headline)
                
                Spacer()
                
                if playlist.totalTrackCount > 0 {
                    Text(playlist.estimatedDurationText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Phase pills
            if !playlist.phases.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(playlist.phases) { phase in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(phase.zone.color)
                                    .frame(width: 8, height: 8)
                                Text("\(phase.tracks.count)/\(phase.targetTrackCount)")
                                    .font(.caption2.bold())
                                Text(phase.zone.rawValue)
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(phase.zone.color.opacity(0.15), in: Capsule())
                        }
                    }
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onPlay) {
                    Label("Play All", systemImage: "play.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(playlist.totalTrackCount > 0 ? AnyShapeStyle(.green.gradient) : AnyShapeStyle(.gray.gradient), in: Capsule())
                }
                .disabled(playlist.totalTrackCount == 0)
                
                Button(action: onRandomize) {
                    Label("Randomize", systemImage: "shuffle")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.orange.opacity(0.15), in: Capsule())
                }
                
                Spacer()
                
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Create Workout Playlist View

struct CreateWorkoutPlaylistView: View {
    @Environment(WorkoutPlaylistManager.self) private var playlistManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var phases: [WorkoutPhase] = []
    @State private var showingAddPhase = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Playlist Name") {
                    TextField("e.g. Morning Run", text: $name)
                }
                
                Section("Phases") {
                    if phases.isEmpty {
                        Text("Add workout phases with different BPM zones")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(phases) { phase in
                            HStack {
                                Circle()
                                    .fill(phase.zone.color)
                                    .frame(width: 12, height: 12)
                                
                                Text(phase.zone.rawValue)
                                    .font(.subheadline.bold())
                                
                                Spacer()
                                
                                Text("\(phase.targetTrackCount) songs")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { offsets in
                            phases.remove(atOffsets: offsets)
                        }
                        .onMove { source, destination in
                            phases.move(fromOffsets: source, toOffset: destination)
                        }
                    }
                    
                    Button {
                        showingAddPhase = true
                    } label: {
                        Label("Add Phase", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("New Workout Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let finalName = name.isEmpty ? "New Workout" : name
                        playlistManager.createPlaylist(name: finalName, phases: phases)
                        dismiss()
                    }
                    .disabled(phases.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddPhase) {
                AddPhaseSheet { newPhase in
                    phases.append(newPhase)
                }
            }
        }
    }
}

// MARK: - Edit Workout Playlist View

struct EditWorkoutPlaylistView: View {
    @Environment(WorkoutPlaylistManager.self) private var playlistManager
    @Environment(SpotifyManager.self) private var spotifyManager
    @Environment(PlaybackManager.self) private var playbackManager
    @Environment(\.dismiss) private var dismiss
    
    @State var playlist: WorkoutPlaylist
    @State private var showingAddPhase = false
    
    var body: some View {
        NavigationStack {
            List {
                // Name section
                Section("Playlist Name") {
                    TextField("Playlist name", text: $playlist.name)
                }
                
                // Phases
                ForEach(Array(playlist.phases.enumerated()), id: \.element.id) { phaseIndex, phase in
                    Section {
                        // Phase header with zone info
                        HStack {
                            Circle()
                                .fill(phase.zone.color)
                                .frame(width: 12, height: 12)
                            
                            Text(phase.zone.rawValue)
                                .font(.subheadline.bold())
                            
                            Text("\(phase.zone.bpmRange.lowerBound)-\(phase.zone.bpmRange.upperBound) BPM")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            // Play zone button
                            if !phase.tracks.isEmpty {
                                Button {
                                    playbackManager.playQueue(tracks: phase.tracks)
                                } label: {
                                    Image(systemName: "play.fill")
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                        .padding(6)
                                        .background(phase.zone.color.gradient, in: Circle())
                                }
                                .buttonStyle(.plain)
                            }
                            
                            // Randomize phase button
                            Button {
                                playlistManager.randomizePhase(
                                    playlistId: playlist.id,
                                    phaseId: phase.id,
                                    tracksByZone: spotifyManager.tracksByZone
                                )
                                // Refresh local state
                                if let updated = playlistManager.playlists.first(where: { $0.id == playlist.id }) {
                                    playlist = updated
                                }
                            } label: {
                                Image(systemName: "shuffle")
                                    .font(.caption)
                                    .foregroundStyle(phase.zone.color)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Stepper for target count
                        Stepper("Target: \(phase.targetTrackCount) songs", value: phaseBinding(phaseIndex).targetTrackCount, in: 1...20)
                            .font(.caption)
                        
                        // Tracks in this phase
                        if phase.tracks.isEmpty {
                            Text("No tracks — tap shuffle to auto-fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(phase.tracks) { track in
                                HStack(spacing: 10) {
                                    // Mini album art
                                    if let imageURL = track.album?.images?.first?.url,
                                       let url = URL(string: imageURL) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(phase.zone.color.opacity(0.3))
                                        }
                                        .frame(width: 36, height: 36)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(track.name)
                                            .font(.caption.bold())
                                            .lineLimit(1)
                                        Text(track.artistNames)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    // Play individual track
                                    Button {
                                        playbackManager.togglePlayPause(track: track)
                                    } label: {
                                        Image(systemName: playbackManager.isCurrentTrack(track) && playbackManager.isPlaying ? "pause.fill" : "play.fill")
                                            .font(.caption)
                                            .foregroundStyle(phase.zone.color)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .onDelete { offsets in
                                playlist.phases[phaseIndex].tracks.remove(atOffsets: offsets)
                            }
                        }
                    } header: {
                        Text("Phase \(phaseIndex + 1)")
                    }
                }
                .onDelete { offsets in
                    playlist.phases.remove(atOffsets: offsets)
                }
                .onMove { source, destination in
                    playlist.phases.move(fromOffsets: source, toOffset: destination)
                }
                
                // Add phase
                Section {
                    Button {
                        showingAddPhase = true
                    } label: {
                        Label("Add Phase", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Edit Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        playlistManager.updatePlaylist(playlist)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddPhase) {
                AddPhaseSheet { newPhase in
                    playlist.phases.append(newPhase)
                }
            }
        }
    }
    
    private func phaseBinding(_ index: Int) -> Binding<WorkoutPhase> {
        Binding(
            get: { playlist.phases[index] },
            set: { playlist.phases[index] = $0 }
        )
    }
}

// MARK: - Add Phase Sheet

struct AddPhaseSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedZone: HeartRateZone = .warmUp
    @State private var trackCount: Int = 2
    
    let onAdd: (WorkoutPhase) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("BPM Zone") {
                    Picker("Zone", selection: $selectedZone) {
                        ForEach(HeartRateZone.allCases, id: \.self) { zone in
                            HStack {
                                Circle()
                                    .fill(zone.color)
                                    .frame(width: 10, height: 10)
                                Text("\(zone.rawValue) (\(zone.bpmRange.lowerBound)-\(zone.bpmRange.upperBound) BPM)")
                            }
                            .tag(zone)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                
                Section("Number of Songs") {
                    Stepper("\(trackCount) songs", value: $trackCount, in: 1...20)
                }
            }
            .navigationTitle("Add Phase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let phase = WorkoutPhase(zone: selectedZone, targetTrackCount: trackCount)
                        onAdd(phase)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    WorkoutView()
        .environment(WorkoutPlaylistManager())
        .environment(SpotifyManager())
        .environment(PlaybackManager())
        .environment(HealthKitManager())
}
