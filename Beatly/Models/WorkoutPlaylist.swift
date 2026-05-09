import Foundation

struct WorkoutPhase: Identifiable, Codable, Hashable {
    let id: UUID
    var zone: HeartRateZone
    var targetTrackCount: Int
    var tracks: [SpotifyTrack]
    
    init(id: UUID = UUID(), zone: HeartRateZone, targetTrackCount: Int = 2, tracks: [SpotifyTrack] = []) {
        self.id = id
        self.zone = zone
        self.targetTrackCount = targetTrackCount
        self.tracks = tracks
    }
}

struct WorkoutPlaylist: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var phases: [WorkoutPhase]
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), name: String = "New Workout", phases: [WorkoutPhase] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.phases = phases
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var allTracks: [SpotifyTrack] {
        phases.flatMap { $0.tracks }
    }
    
    var estimatedDuration: TimeInterval {
        allTracks.compactMap { $0.duration_ms }.reduce(0) { $0 + Double($1) / 1000.0 }
    }
    
    var estimatedDurationText: String {
        let totalSeconds = Int(estimatedDuration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
    
    var totalTrackCount: Int {
        phases.reduce(0) { $0 + $1.tracks.count }
    }
    
    var phaseSummary: String {
        phases.map { "\($0.targetTrackCount) \($0.zone.rawValue)" }.joined(separator: " → ")
    }
}
