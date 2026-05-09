//
//  PlaybackManager.swift
//  Beatly
//
//  Created by Gabriel Netto on 30/04/26.
//

import Foundation
import AVFoundation
import UIKit

/// Manages music playback — tries Spotify app first, falls back to 30-sec preview via AVPlayer
@Observable
class PlaybackManager {
    
    // MARK: - Properties
    
    /// The track currently loaded for playback
    var currentTrack: SpotifyTrack?
    
    /// Whether audio is currently playing
    var isPlaying = false
    
    /// Playback progress from 0.0 to 1.0
    var playbackProgress: Double = 0
    
    /// Current playback mode
    var playbackMode: PlaybackMode = .none
    
    /// AVPlayer for preview URL playback
    private var avPlayer: AVPlayer?
    
    /// Observer for tracking playback progress
    private var timeObserver: Any?
    
    /// Observer for detecting when playback finishes
    private var endObserver: NSObjectProtocol?
    
    // MARK: - Queue Properties
    
    /// Queue of tracks for sequential playback
    var queue: [SpotifyTrack] = []
    
    /// Current index in the queue
    var currentQueueIndex: Int = 0
    
    /// Whether we're in queue playback mode
    var isQueueMode: Bool { !queue.isEmpty }
    
    /// Whether there's a next track in the queue
    var hasNext: Bool { !queue.isEmpty && currentQueueIndex < queue.count - 1 }
    
    /// Whether there's a previous track in the queue
    var hasPrevious: Bool { !queue.isEmpty && currentQueueIndex > 0 }
    
    /// Queue position display text (e.g. "3 of 12")
    var queuePositionText: String {
        guard isQueueMode else { return "" }
        return "\(currentQueueIndex + 1) of \(queue.count)"
    }
    
    // MARK: - Auto DJ Properties
    
    /// Whether Auto DJ mode is active (picks next song by current heart rate)
    var isAutoDJActive = false
    
    /// The current zone being played in Auto DJ mode
    var autoDJCurrentZone: HeartRateZone?
    
    /// Track pool for Auto DJ — set externally from SpotifyManager.tracksByZone
    var autoDJTrackPool: [HeartRateZone: [SpotifyTrack]] = [:]
    
    /// Heart rate provider — set externally from HealthKitManager
    var autoDJHeartRateProvider: (() -> Int)?
    
    /// History of tracks already played in this Auto DJ session (to avoid repeats)
    private var autoDJPlayedTrackIds: Set<String> = []
    
    /// Total tracks played in current Auto DJ session
    var autoDJTracksPlayed: Int { autoDJPlayedTrackIds.count }
    
    // MARK: - Playback Mode
    
    enum PlaybackMode {
        case spotifyApp  // Playing via Spotify app deep link
        case preview     // Playing 30-sec preview via AVPlayer
        case none        // Nothing playing
    }
    
    // MARK: - Main Playback Controls
    
    /// Play a track — tries Spotify app first, falls back to preview URL
    func play(track: SpotifyTrack) {
        // If tapping the same track that's playing, toggle pause
        if currentTrack?.id == track.id && isPlaying {
            pause()
            return
        }
        
        // If tapping the same track that's paused, resume
        if currentTrack?.id == track.id && !isPlaying && playbackMode == .preview {
            resume()
            return
        }
        
        // Clear queue when playing a single track directly
        queue = []
        currentQueueIndex = 0
        
        playSingle(track: track)
    }
    
    /// Play a queue of tracks sequentially, starting from the first
    func playQueue(tracks: [SpotifyTrack]) {
        guard !tracks.isEmpty else { return }
        
        stop()
        queue = tracks
        currentQueueIndex = 0
        playSingle(track: tracks[0])
    }
    
    /// Advance to the next track in the queue
    func playNext() {
        guard hasNext else { return }
        currentQueueIndex += 1
        stopWithoutClearingQueue()
        playSingle(track: queue[currentQueueIndex])
    }
    
    /// Go back to the previous track in the queue
    func playPrevious() {
        guard hasPrevious else { return }
        currentQueueIndex -= 1
        stopWithoutClearingQueue()
        playSingle(track: queue[currentQueueIndex])
    }
    
    /// Internal: play a single track without touching the queue
    private func playSingle(track: SpotifyTrack) {
        // Stop current playback (preserve queue)
        removeObservers()
        avPlayer?.pause()
        avPlayer = nil
        isPlaying = false
        playbackProgress = 0
        playbackMode = .none
        
        currentTrack = track
        
        // Try Spotify app deep link first
        if trySpotifyApp(trackId: track.id) {
            playbackMode = .spotifyApp
            isPlaying = true
            return
        }
        
        // Fall back to preview URL
        if let previewURLString = track.preview_url,
           let previewURL = URL(string: previewURLString) {
            playPreview(url: previewURL)
        } else {
            print("⚠️ No preview URL available for: \(track.name)")
            playbackMode = .none
        }
    }
    
    /// Pause current playback
    func pause() {
        avPlayer?.pause()
        isPlaying = false
    }
    
    /// Resume paused playback
    func resume() {
        avPlayer?.play()
        isPlaying = true
    }
    
    /// Stop playback and reset (clears queue and Auto DJ)
    func stop() {
        removeObservers()
        avPlayer?.pause()
        avPlayer = nil
        isPlaying = false
        playbackProgress = 0
        playbackMode = .none
        queue = []
        currentQueueIndex = 0
        if isAutoDJActive {
            isAutoDJActive = false
            autoDJCurrentZone = nil
            autoDJTrackPool = [:]
            autoDJHeartRateProvider = nil
            autoDJPlayedTrackIds = []
        }
    }
    
    /// Stop current audio without clearing the queue
    private func stopWithoutClearingQueue() {
        removeObservers()
        avPlayer?.pause()
        avPlayer = nil
        isPlaying = false
        playbackProgress = 0
        playbackMode = .none
    }
    
    /// Toggle play/pause for a track
    func togglePlayPause(track: SpotifyTrack) {
        play(track: track)
    }
    
    /// Check if a specific track is the one currently playing
    func isCurrentTrack(_ track: SpotifyTrack) -> Bool {
        currentTrack?.id == track.id
    }
    
    // MARK: - Auto DJ
    
    /// Start Auto DJ mode — picks songs based on live heart rate
    func startAutoDJ(tracksByZone: [HeartRateZone: [SpotifyTrack]], heartRateProvider: @escaping () -> Int) {
        stop()
        isAutoDJActive = true
        autoDJTrackPool = tracksByZone
        autoDJHeartRateProvider = heartRateProvider
        autoDJPlayedTrackIds = []
        autoDJCurrentZone = nil
        
        // Pick and play the first track
        playNextAutoDJTrack()
    }
    
    /// Stop Auto DJ mode
    func stopAutoDJ() {
        isAutoDJActive = false
        autoDJCurrentZone = nil
        autoDJTrackPool = [:]
        autoDJHeartRateProvider = nil
        autoDJPlayedTrackIds = []
        stop()
    }
    
    /// Pick the next track based on current heart rate and play it
    private func playNextAutoDJTrack() {
        guard isAutoDJActive else { return }
        
        let heartRate = autoDJHeartRateProvider?() ?? 80
        let zone = HeartRateZone.from(bpm: heartRate)
        autoDJCurrentZone = zone
        
        // Get available tracks for this zone, excluding already-played ones
        let available = (autoDJTrackPool[zone] ?? []).filter { !autoDJPlayedTrackIds.contains($0.id) }
        
        // If zone is exhausted, try any zone as fallback
        let track: SpotifyTrack?
        if let picked = available.randomElement() {
            track = picked
        } else {
            // Fallback: pick from any zone, excluding played
            let allAvailable = autoDJTrackPool.values.flatMap { $0 }.filter { !autoDJPlayedTrackIds.contains($0.id) }
            track = allAvailable.randomElement()
        }
        
        guard let nextTrack = track else {
            // All tracks exhausted — reset played history and try again
            autoDJPlayedTrackIds = []
            let retryAvailable = (autoDJTrackPool[zone] ?? []).randomElement()
                ?? autoDJTrackPool.values.flatMap({ $0 }).randomElement()
            if let retryTrack = retryAvailable {
                autoDJPlayedTrackIds.insert(retryTrack.id)
                playSingleAutoDJ(track: retryTrack)
            } else {
                stopAutoDJ()
            }
            return
        }
        
        autoDJPlayedTrackIds.insert(nextTrack.id)
        playSingleAutoDJ(track: nextTrack)
    }
    
    /// Play a single track in Auto DJ mode (doesn't clear Auto DJ state)
    private func playSingleAutoDJ(track: SpotifyTrack) {
        removeObservers()
        avPlayer?.pause()
        avPlayer = nil
        isPlaying = false
        playbackProgress = 0
        playbackMode = .none
        // Clear queue so isQueueMode is false
        queue = []
        currentQueueIndex = 0
        
        currentTrack = track
        
        if trySpotifyApp(trackId: track.id) {
            playbackMode = .spotifyApp
            isPlaying = true
            return
        }
        
        if let previewURLString = track.preview_url,
           let previewURL = URL(string: previewURLString) {
            playPreviewAutoDJ(url: previewURL)
        } else {
            // Skip tracks without preview — try next
            print("⚠️ Auto DJ skipping (no preview): \(track.name)")
            playNextAutoDJTrack()
        }
    }
    
    /// Play preview with Auto DJ end-of-track handler
    private func playPreviewAutoDJ(url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Audio session error: \(error)")
        }
        
        let playerItem = AVPlayerItem(url: url)
        avPlayer = AVPlayer(playerItem: playerItem)
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = avPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self,
                  let duration = self.avPlayer?.currentItem?.duration,
                  duration.seconds > 0, !duration.seconds.isNaN else { return }
            self.playbackProgress = time.seconds / duration.seconds
        }
        
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.playNextAutoDJTrack()
        }
        
        avPlayer?.play()
        playbackMode = .preview
        isPlaying = true
        
        print("🎧 Auto DJ playing: \(currentTrack?.name ?? "unknown") [Zone: \(autoDJCurrentZone?.rawValue ?? "?")]")
    }
    
    // MARK: - Spotify App Deep Link
    
    /// Try to open the track in the Spotify app
    private func trySpotifyApp(trackId: String) -> Bool {
        guard let spotifyURL = URL(string: "spotify:track:\(trackId)") else { return false }
        
        let canOpen = UIApplication.shared.canOpenURL(spotifyURL)
        if canOpen {
            UIApplication.shared.open(spotifyURL)
            print("✅ Opening track in Spotify app")
            return true
        }
        
        print("⚠️ Spotify app not installed, using preview")
        return false
    }
    
    // MARK: - AVPlayer Preview Playback
    
    /// Play a 30-second preview via AVPlayer
    private func playPreview(url: URL) {
        // Configure audio session for playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Audio session error: \(error)")
        }
        
        let playerItem = AVPlayerItem(url: url)
        avPlayer = AVPlayer(playerItem: playerItem)
        
        // Track progress
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = avPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self,
                  let duration = self.avPlayer?.currentItem?.duration,
                  duration.seconds > 0, !duration.seconds.isNaN else { return }
            self.playbackProgress = time.seconds / duration.seconds
        }
        
        // Detect when playback ends — auto-advance queue if applicable
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            if self.hasNext {
                self.playNext()
            } else {
                self.isPlaying = false
                self.playbackProgress = 0
                self.queue = []
                self.currentQueueIndex = 0
            }
        }
        
        avPlayer?.play()
        playbackMode = .preview
        isPlaying = true
        
        print("▶️ Playing preview for: \(currentTrack?.name ?? "unknown")")
    }
    
    // MARK: - Cleanup
    
    private func removeObservers() {
        if let observer = timeObserver {
            avPlayer?.removeTimeObserver(observer)
            timeObserver = nil
        }
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }
    }
    
    deinit {
        removeObservers()
    }
}
