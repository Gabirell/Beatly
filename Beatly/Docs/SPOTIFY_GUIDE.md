# 🎵 Spotify Integration - Complete Guide



## What We Just Created

I've set up the complete Spotify integration system for Beatly! Here's what you now have:

---

## 📁 New Files Created

1. **SPOTIFY_SETUP.md** - Setup instructions
2. **SpotifyManager.swift** - Complete Spotify integration
3. **SPOTIFY_GUIDE.md** - This comprehensive guide

---

## 🎯 What the Spotify Manager Does

### 1. **Authentication** 🔐
```swift
// Get login URL
let url = spotifyManager.getAuthorizationURL()

// After user logs in, exchange code for token
try await spotifyManager.exchangeCodeForToken(code: authCode)
```

### 2. **Fetch User's Top Tracks** 🎵
```swift
// Get user's 50 most played songs
try await spotifyManager.fetchTopTracks()
print(spotifyManager.topTracks)  // Array of SpotifyTrack objects
```

### 3. **Get BPM (Tempo) for Songs** 💓
```swift
// Get audio features including BPM
let features = try await spotifyManager.getAudioFeatures(trackID: "track_id")
print("BPM: \(features.tempo)")  // e.g., 120.5
```

### 4. **Organize Songs by BPM Zones** 📊
```swift
// Automatically categorize songs by workout intensity
try await spotifyManager.organizeTracksByBPM()

// Access songs by zone
let cardioSongs = spotifyManager.tracksByZone[.cardio]  // 120-140 BPM
let peakSongs = spotifyManager.tracksByZone[.peak]      // 140-160 BPM
```

### 5. **Search for Songs by BPM** 🔍
```swift
// Find songs within specific BPM range
let tracks = try await spotifyManager.searchTracksByBPM(minBPM: 120, maxBPM: 140)
```

---

## 🧠 Understanding BPM Matching

### Heart Rate to Music BPM Zones:

| Your HR | Music BPM | Zone | Use Case |
|---------|-----------|------|----------|
| 60-90   | 60-90     | Warm-up | Stretching, cool down |
| 90-120  | 90-120    | Fat Burn | Walking, light jog |
| 120-140 | 120-140   | Cardio | Running, cycling |
| 140-160 | 140-160   | Peak | HIIT, sprints |
| 160+    | 160+      | Maximum | Max effort |

**The Concept:**
- When your heart beats at 120 BPM, music at 120 BPM feels natural and motivating
- It creates a synchronized rhythm between your body and the music
- Helps maintain pace and energy level

---

## 📝 How to Use in Your App

### Step 1: Setup (One-time)

1. **Get Spotify Credentials:**
   - Go to https://developer.spotify.com/dashboard
   - Create an app
   - Copy your Client ID and Client Secret

2. **Update SpotifyManager.swift:**
   ```swift
   private let clientID = "your_actual_client_id"
   private let clientSecret = "your_actual_client_secret"
   ```

3. **Configure Info.plist:**
   - Add URL scheme: `beatly`
   - Add queried URL schemes: `spotify`, `spotify-action`

### Step 2: Integration Code

Here's how to use it in your views:

```swift
import SwiftUI

struct PlaylistView: View {
    @State private var spotifyManager = SpotifyManager()
    @State private var showingLogin = false
    
    var body: some View {
        VStack {
            if spotifyManager.isAuthenticated {
                // Show user's playlists organized by BPM
                List {
                    ForEach(HeartRateZone.allCases, id: \.self) { zone in
                        Section(zone.rawValue) {
                            let tracks = spotifyManager.tracksByZone[zone] ?? []
                            ForEach(tracks) { track in
                                TrackRow(track: track)
                            }
                        }
                    }
                }
            } else {
                // Show login button
                Button("Connect Spotify") {
                    showingLogin = true
                }
            }
        }
        .sheet(isPresented: $showingLogin) {
            SpotifyLoginView(manager: spotifyManager)
        }
        .task {
            if spotifyManager.isAuthenticated {
                try? await spotifyManager.fetchTopTracks()
                try? await spotifyManager.organizeTracksByBPM()
            }
        }
    }
}
```

---

## 🎓 Learning: How the Code Works

### 1. API Authentication Flow

```
User taps "Connect Spotify"
    ↓
App opens Spotify login in Safari
    ↓
User grants permission
    ↓
Spotify redirects to: beatly://callback?code=ABC123
    ↓
App catches the redirect
    ↓
Exchange code for access token
    ↓
Use token for all API requests
```

### 2. Fetching BPM

```swift
// 1. Get user's top tracks
let tracks = await spotifyManager.fetchTopTracks()

// 2. Extract track IDs
let ids = tracks.map { $0.id }

// 3. Fetch audio features (includes BPM)
let features = await spotifyManager.getAudioFeaturesForTracks(trackIDs: ids)

// 4. Each feature has tempo (BPM)
for feature in features {
    print("\(feature.id): \(feature.tempo) BPM")
}
```

### 3. Matching Songs to Heart Rate

```swift
// Current heart rate from HealthKit
let currentHeartRate = 135  // BPM

// Find matching zone
let zone = HeartRateZone.from(bpm: currentHeartRate)  // Returns .cardio

// Get songs in that zone (120-140 BPM)
let matchingSongs = spotifyManager.tracksByZone[zone]

// Play songs that match your current pace!
```

---

## 🔑 Key Spotify API Endpoints

### 1. Get User's Top Tracks
```
GET https://api.spotify.com/v1/me/top/tracks
```
Returns: List of most played songs

### 2. Get Audio Features
```
GET https://api.spotify.com/v1/audio-features/{id}
```
Returns: Tempo (BPM), energy, danceability, etc.

### 3. Search
```
GET https://api.spotify.com/v1/search?q=...&type=track
```
Returns: Tracks matching search criteria

---

## 🎨 Example: Real-World Usage

### Scenario: User starts a workout

```swift
// 1. User's heart rate: 125 BPM
let currentBPM = healthManager.currentHeartRate  // 125

// 2. Find matching zone
let zone = HeartRateZone.from(bpm: currentBPM)  // .cardio

// 3. Get songs for that zone
let playlist = spotifyManager.tracksByZone[zone]  // Songs with 120-140 BPM

// 4. Play the playlist!
// Songs naturally match their workout intensity
```

### Scenario: Heart rate increases

```swift
// Heart rate goes up to 150 BPM
let newBPM = 150

// Zone changes
let newZone = HeartRateZone.from(bpm: newBPM)  // .peak

// Switch to faster music (140-160 BPM)
let newPlaylist = spotifyManager.tracksByZone[newZone]

// Music automatically adjusts to match intensity! 🎵💪
```

---

## 📊 Data Models Explained

### SpotifyTrack
```swift
struct SpotifyTrack {
    let id: String           // Unique track ID
    let name: String         // Song title
    let artists: [Artist]    // Who made it
    let album: Album         // Album info (includes cover art)
    let duration_ms: Int     // Length in milliseconds
    let preview_url: String? // 30-second preview URL
}
```

### AudioFeatures
```swift
struct AudioFeatures {
    let tempo: Double        // ← BPM (e.g., 120.5)
    let energy: Double       // 0.0-1.0 (how energetic)
    let danceability: Double // 0.0-1.0 (how danceable)
    let valence: Double      // 0.0-1.0 (how happy/positive)
}
```

---

## 🚀 Next Steps

### To Complete Spotify Integration:

1. **Get Credentials** ✅
   - Create Spotify Developer account
   - Get Client ID and Secret

2. **Update Code** ✅
   - Replace placeholder credentials in SpotifyManager.swift

3. **Test Authentication** 🔄
   - Build a simple login view
   - Test the OAuth flow

4. **Build UI** 🎨
   - Create playlist views
   - Show songs organized by BPM
   - Display album artwork

5. **Connect to HealthKit** 🔗
   - Match current heart rate to appropriate BPM zone
   - Auto-select playlists based on workout intensity

---

## 💡 Cool Features You Can Build

### 1. Dynamic Playlist
Music automatically changes as heart rate changes

### 2. BPM Visualizer
Show songs organized by BPM in a visual chart

### 3. Workout Planner
Create custom workout plans with music for each phase

### 4. Discovery Mode
Find new music that matches your workout zones

---

## ⚠️ Important Notes

### Security:
- **NEVER commit Client Secret to Git!**
- Use environment variables or secure storage
- Client ID is okay to expose, Secret is not

### Rate Limits:
- Spotify has API rate limits
- Don't make too many requests too quickly
- Cache results when possible

### Token Expiration:
- Access tokens expire after 1 hour
- You'll need to implement token refresh
- (We'll add this in a future update)

---

## 📚 Want to Learn More?

**Spotify API Documentation:**
- https://developer.spotify.com/documentation/web-api

**Key Topics:**
- Authorization (OAuth 2.0)
- Audio Features
- Recommendations
- Playlists

---

**Ready to integrate Spotify?** Let me know when you have your Client ID and Secret, and we'll test it together! 🎵🚀

*Created: April 10, 2026*
*Phase 4: Spotify Integration*
