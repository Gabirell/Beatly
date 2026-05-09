import Foundation
import SwiftUI

/// Manages CRUD operations and persistence for custom workout playlists
@Observable
class WorkoutPlaylistManager {
    
    // MARK: - Properties
    
    var playlists: [WorkoutPlaylist] = []
    
    private let storageKey = "savedWorkoutPlaylists"
    
    // MARK: - Init
    
    init() {
        load()
        seedTemplatesIfNeeded()
    }
    
    // MARK: - CRUD
    
    /// Create a new playlist and return it
    @discardableResult
    func createPlaylist(name: String = "New Workout", phases: [WorkoutPhase] = []) -> WorkoutPlaylist {
        let playlist = WorkoutPlaylist(name: name, phases: phases)
        playlists.append(playlist)
        save()
        return playlist
    }
    
    /// Update an existing playlist
    func updatePlaylist(_ playlist: WorkoutPlaylist) {
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        var updated = playlist
        updated.updatedAt = Date()
        playlists[index] = updated
        save()
    }
    
    /// Delete a playlist by ID
    func deletePlaylist(_ id: UUID) {
        playlists.removeAll { $0.id == id }
        save()
    }
    
    /// Delete playlists at offsets (for List onDelete)
    func deletePlaylists(at offsets: IndexSet) {
        playlists.remove(atOffsets: offsets)
        save()
    }
    
    /// Move playlists (for List onMove)
    func movePlaylists(from source: IndexSet, to destination: Int) {
        playlists.move(fromOffsets: source, toOffset: destination)
        save()
    }
    
    // MARK: - Randomizer
    
    /// Auto-fill all phases of a playlist with random tracks from the zone pools
    func randomizeTracks(for playlistId: UUID, tracksByZone: [HeartRateZone: [SpotifyTrack]]) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistId }) else { return }
        
        for phaseIndex in playlists[index].phases.indices {
            let zone = playlists[index].phases[phaseIndex].zone
            let count = playlists[index].phases[phaseIndex].targetTrackCount
            let available = tracksByZone[zone] ?? []
            playlists[index].phases[phaseIndex].tracks = Array(available.shuffled().prefix(count))
        }
        
        playlists[index].updatedAt = Date()
        save()
    }
    
    /// Auto-fill a single phase with random tracks from the zone pool
    func randomizePhase(playlistId: UUID, phaseId: UUID, tracksByZone: [HeartRateZone: [SpotifyTrack]]) {
        guard let playlistIndex = playlists.firstIndex(where: { $0.id == playlistId }),
              let phaseIndex = playlists[playlistIndex].phases.firstIndex(where: { $0.id == phaseId }) else { return }
        
        let zone = playlists[playlistIndex].phases[phaseIndex].zone
        let count = playlists[playlistIndex].phases[phaseIndex].targetTrackCount
        let available = tracksByZone[zone] ?? []
        playlists[playlistIndex].phases[phaseIndex].tracks = Array(available.shuffled().prefix(count))
        playlists[playlistIndex].updatedAt = Date()
        save()
    }
    
    // MARK: - Templates
    
    /// Seed the default workout templates if the user has no playlists
    func seedTemplatesIfNeeded() {
        guard playlists.isEmpty else { return }
        
        // 1. Morning Cardio — gentle warm-up into sustained cardio, cool-down
        createPlaylist(name: "Morning Cardio", phases: [
            WorkoutPhase(zone: .warmUp, targetTrackCount: 2),
            WorkoutPhase(zone: .fatBurn, targetTrackCount: 3),
            WorkoutPhase(zone: .cardio, targetTrackCount: 4),
            WorkoutPhase(zone: .fatBurn, targetTrackCount: 2),
            WorkoutPhase(zone: .warmUp, targetTrackCount: 1),
        ])
        
        // 2. HIIT Session — alternating bursts of peak intensity and recovery
        createPlaylist(name: "HIIT Session", phases: [
            WorkoutPhase(zone: .warmUp, targetTrackCount: 1),
            WorkoutPhase(zone: .peak, targetTrackCount: 2),
            WorkoutPhase(zone: .fatBurn, targetTrackCount: 1),
            WorkoutPhase(zone: .maximum, targetTrackCount: 2),
            WorkoutPhase(zone: .fatBurn, targetTrackCount: 1),
            WorkoutPhase(zone: .peak, targetTrackCount: 2),
            WorkoutPhase(zone: .warmUp, targetTrackCount: 1),
        ])
        
        // 3. Long Run — gradual build-up, sustained effort, gradual cool-down
        createPlaylist(name: "Long Run", phases: [
            WorkoutPhase(zone: .warmUp, targetTrackCount: 3),
            WorkoutPhase(zone: .fatBurn, targetTrackCount: 4),
            WorkoutPhase(zone: .cardio, targetTrackCount: 5),
            WorkoutPhase(zone: .fatBurn, targetTrackCount: 3),
            WorkoutPhase(zone: .warmUp, targetTrackCount: 2),
        ])
    }
    
    // MARK: - Persistence
    
    private func save() {
        guard let data = try? JSONEncoder().encode(playlists) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([WorkoutPlaylist].self, from: data) else { return }
        playlists = decoded
    }
}
