# Beatly — Complete App Documentation

> A workout music companion for iOS that matches music BPM to your heart rate intensity in real time.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Project Structure](#project-structure)
3. [App Entry Point](#app-entry-point)
4. [Managers (Business Logic)](#managers)
5. [Models (Data Layer)](#models)
6. [Views (UI Layer)](#views)
7. [Theme System](#theme-system)
8. [OAuth Flows](#oauth-flows)
9. [Music Playback System](#music-playback-system)
10. [Heart Rate & Health Integration](#heart-rate--health-integration)
11. [Configuration Files](#configuration-files)
12. [How Everything Connects](#how-everything-connects)

---

## Architecture Overview

Beatly uses **SwiftUI** with the modern **`@Observable`** pattern (not Combine/ObservableObject). All managers are:

- Declared as `@State private var` in `BeatlyApp`
- Injected into the view hierarchy via `.environment()`
- Accessed in views via `@Environment(ManagerType.self)`

This gives every view in the app access to shared state without prop-drilling.

```
BeatlyApp (root)
  ├── SpotifyManager        — Spotify OAuth + API
  ├── HealthKitManager      — Heart rate data
  ├── LocationManager       — GPS permissions
  ├── MusicKitManager       — Apple Music auth
  ├── StravaManager         — Strava OAuth
  ├── YouTubeMusicManager   — YouTube Music OAuth
  ├── DeezerManager         — Deezer OAuth
  ├── PlaybackManager       — Audio playback engine
  ├── WorkoutPlaylistManager— Custom playlist CRUD
  └── ThemeManager          — Visual theme persistence
```

---

## Project Structure

```
Beatly/
├── BeatlyApp.swift          ← App entry point, wires all managers
├── ContentView.swift        ← Root view (just wraps MainTabView)
├── Info.plist               ← URL schemes, permissions, background modes
├── Beatly.entitlements      ← HealthKit entitlement
│
├── Managers/                ← Business logic layer (all @Observable)
│   ├── SpotifyManager.swift
│   ├── HealthKitManager.swift
│   ├── PlaybackManager.swift
│   ├── WorkoutPlaylistManager.swift
│   ├── ThemeManager.swift
│   ├── LocationManager.swift
│   ├── MusicKitManager.swift
│   ├── StravaManager.swift
│   ├── YouTubeMusicManager.swift
│   └── DeezerManager.swift
│
├── Models/                  ← Data structures
│   └── WorkoutPlaylist.swift
│
├── Views/                   ← UI layer
│   ├── MainTabView.swift
│   ├── HomeView.swift
│   ├── PlaylistView.swift
│   ├── WorkoutView.swift
│   ├── ProfileView.swift
│   ├── HeartLogoView.swift
│   └── SpotifyLoginView.swift
│
└── Docs/                    ← Documentation
    └── (various .md files)
```

---

## App Entry Point

### `BeatlyApp.swift`

The `@main` struct that initializes everything.

**What it does:**
1. Creates all 10 managers as `@State private var` properties
2. Injects them into the view tree via `.environment()`
3. Listens for OAuth callback URLs via `.onOpenURL`
4. Routes callbacks to the correct manager based on the URL host:

| URL | Handler |
|-----|---------|
| `beatly://callback` | Spotify token exchange |
| `beatly://strava-callback` | Strava token exchange |
| `beatly://youtube-callback` | YouTube Music token exchange |
| `beatly://deezer-callback` | Deezer token exchange |

### `ContentView.swift`

A thin wrapper that simply displays `MainTabView()`. Exists as the default Xcode entry view.

---

## Managers

### `SpotifyManager.swift` — The Core Music Engine

This is the largest and most important manager. It handles all Spotify integration.

**Credentials:**
- Client ID: `3e667d245f874478ab36c4070f7b40be`
- Client Secret: `ea55c05fe75d4fc4b4f1aacbc8ce9b44`
- Redirect URI: `beatly://callback`

**Key Properties:**
- `accessToken: String?` — OAuth token
- `isAuthenticated: Bool` — computed, checks if token exists
- `topTracks: [SpotifyTrack]` — user's tracks fetched from API
- `tracksByZone: [HeartRateZone: [SpotifyTrack]]` — tracks sorted by BPM into heart rate zones
- `debugResponse: String?` — raw API response for troubleshooting

**Key Methods:**
- `getAuthorizationURL() -> URL?` — builds the Spotify OAuth URL with scopes
- `exchangeCodeForToken(code:)` — POST to Spotify token endpoint
- `fetchTopTracks()` — multi-strategy fetch (search API, since personal endpoints return 403 in dev mode)
- `organizeTracksByBPM()` — maps BPM ranges to HeartRateZone enum
- `disconnect()` — clears all auth and data

**Data Models (defined in this file):**

```swift
struct SpotifyTrack: Codable, Identifiable, Hashable
    - id, name, artists, album, duration_ms, preview_url
    - artistNames (computed)

struct Artist: Codable, Hashable
    - id, name

struct Album: Codable, Hashable
    - id, name, images

struct SpotifyImage: Codable, Hashable
    - url, height, width

enum HeartRateZone: String, CaseIterable, Codable, Hashable
    - warmUp ("Warm-up", 60–90 BPM, blue)
    - fatBurn ("Fat Burn", 90–120 BPM, green)
    - cardio ("Cardio", 120–140 BPM, orange)
    - peak ("Peak", 140–160 BPM, red)
    - maximum ("Maximum", 160–200 BPM, purple)
    - from(bpm:) — static factory, maps an integer BPM to a zone
    - bpmRange — the BPM range for each zone
    - color — SwiftUI Color for each zone
```

**Important note about Spotify API (Feb 2026):** Dev mode with Premium accounts returns 403 on most personal endpoints (`/me/top/tracks`, `/me/playlists`). The app uses the Search API as a workaround.

---

### `HealthKitManager.swift` — Heart Rate Monitor

Reads heart rate data from Apple Health (which includes Apple Watch data).

**Key Properties:**
- `currentHeartRate: Int` — latest BPM reading
- `isAvailable: Bool` — device supports HealthKit
- `isAuthorized: Bool` — user granted access

**Key Methods:**
- `requestAuthorization()` — prompts user for HealthKit permission
- `startHeartRateMonitoring()` — starts continuous monitoring via `HKAnchoredObjectQuery` (updates every new sample)
- `stopHeartRateMonitoring()` — stops the query
- `fetchLatestHeartRate()` — one-time query for the most recent reading

**How it works with Apple Watch:**
The Apple Watch writes heart rate samples to HealthKit automatically. This manager simply reads from HealthKit — it doesn't communicate directly with the Watch.

---

### `PlaybackManager.swift` — Audio Playback Engine

Manages all music playback in the app with three modes.

**Playback Strategy (dual approach):**
1. **Spotify App Deep Link** — Opens `spotify:track:{id}` in the Spotify app for full playback
2. **AVPlayer Preview** — Falls back to 30-second preview via `AVFoundation` if Spotify isn't installed

**Single Track Playback:**
- `play(track:)` — main entry, tries Spotify app then preview
- `pause()`, `resume()`, `stop()`
- `togglePlayPause(track:)` — convenience toggle
- `isCurrentTrack(_:) -> Bool` — check if a track is the one playing

**Queue Playback (for playlists/zones):**
- `playQueue(tracks:)` — play an array of tracks sequentially
- `playNext()`, `playPrevious()` — queue navigation
- `hasNext`, `hasPrevious` — computed Booleans
- `queuePositionText` — e.g., "3 of 12"
- Auto-advances to next track when current one ends

**Auto DJ Mode (heart-rate-reactive):**
- `startAutoDJ(tracksByZone:heartRateProvider:)` — begins automatic playback
- `stopAutoDJ()` — ends Auto DJ mode
- When a song ends, reads current heart rate → determines BPM zone → picks a random track from that zone → plays it
- Avoids repeating tracks within a session
- Falls back to other zones if current zone is exhausted
- Skips tracks without preview URLs

**Key Properties:**
- `currentTrack: SpotifyTrack?`
- `isPlaying: Bool`
- `playbackProgress: Double` (0.0 to 1.0)
- `playbackMode: PlaybackMode` (.spotifyApp, .preview, .none)
- `isAutoDJActive: Bool`
- `autoDJCurrentZone: HeartRateZone?`

---

### `WorkoutPlaylistManager.swift` — Custom Playlist CRUD

Manages creation, editing, and persistence of custom workout playlists.

**CRUD Operations:**
- `createPlaylist(name:phases:)` — creates and returns a new playlist
- `updatePlaylist(_:)` — updates an existing playlist
- `deletePlaylist(_:)` — delete by UUID
- `deletePlaylists(at:)` — delete by IndexSet (for List swipe-to-delete)
- `movePlaylists(from:to:)` — reorder (for List drag-to-reorder)

**Randomizer:**
- `randomizeTracks(for:tracksByZone:)` — fills ALL phases with random tracks from the matching zone
- `randomizePhase(playlistId:phaseId:tracksByZone:)` — fills a single phase

**Templates:**
- `seedTemplatesIfNeeded()` — called on init; if no playlists exist, creates 3 defaults:
  1. **Morning Cardio** — Warm-up(2) → Fat Burn(3) → Cardio(4) → Fat Burn(2) → Warm-up(1)
  2. **HIIT Session** — Warm-up(1) → Peak(2) → Fat Burn(1) → Maximum(2) → Fat Burn(1) → Peak(2) → Warm-up(1)
  3. **Long Run** — Warm-up(3) → Fat Burn(4) → Cardio(5) → Fat Burn(3) → Warm-up(2)

**Persistence:**
All playlists are encoded to JSON and stored in `UserDefaults` under key `"savedWorkoutPlaylists"`. They persist across app launches.

---

### `ThemeManager.swift` — Visual Themes

Manages the app's visual theme with 5 options.

**`BeatlyTheme` struct properties:**
- `accentColor` — tab bar tint, buttons
- `heartColor` — heart icon fill
- `headphoneColor` — headphones overlay color
- `backgroundGradientLight` / `backgroundGradientDark` — separate gradients per color scheme
- `glowColor` — glow ring around the heart logo

**5 Built-in Themes:**

| Theme | Heart Color | Feel |
|-------|------------|------|
| Classic | Pink | Clean, default |
| Neon Pulse | Cyan | Electric, cyberpunk |
| Sunset | Orange | Warm, energetic |
| Midnight | Purple | Deep, moody |
| Nature | Green | Earthy, calm |

**Persistence:** Selected theme ID saved to `UserDefaults` under key `"selectedThemeId"`.

---

### `LocationManager.swift` — GPS Permissions

Simple wrapper around `CoreLocation` for requesting location access.

- Uses `CLLocationManagerDelegate` (requires `NSObject` subclass)
- `requestPermission()` → requests "when in use" authorization
- `isAuthorized` → true if `.authorizedWhenInUse` or `.authorizedAlways`
- `statusText` → human-readable status string

---

### `MusicKitManager.swift` — Apple Music Authorization

Handles Apple Music permission via the MusicKit framework.

- `requestAuthorization()` → calls `MusicAuthorization.request()`
- `isAuthorized` → true if status == `.authorized`
- Note: MusicKit is configured in the Apple Developer portal, not in the entitlements file

---

### `StravaManager.swift` — Strava Fitness Tracker

OAuth2 integration with Strava for workout data.

**Credentials:**
- Client ID: `233517`
- Client Secret: `d6db920b88cc9205863b760edaac358e63022ef4`
- Redirect URI: `beatly://strava-callback`
- Strava Callback Domain setting: `strava-callback`

**Methods:**
- `getAuthorizationURL()` — builds Strava OAuth URL
- `exchangeCodeForToken(code:)` — exchanges code for token, extracts athlete name
- `disconnect()` — clears auth

---

### `YouTubeMusicManager.swift` — YouTube Music

Google OAuth2 integration for YouTube Music.

- Redirect URI: `beatly://youtube-callback`
- Scope: `youtube.readonly`
- `exchangeCodeForToken(code:)` → POST to `oauth2.googleapis.com/token`
- `fetchUserProfile()` → GET YouTube channel name
- Credentials: placeholder (`YOUR_GOOGLE_CLIENT_ID`) — needs registration at Google Cloud Console

---

### `DeezerManager.swift` — Deezer

OAuth2 integration for Deezer.

- Redirect URI: `beatly://deezer-callback`
- Permissions: `basic_access, listening_history`
- `exchangeCodeForToken(code:)` → GET to `connect.deezer.com/oauth/access_token.php`
- `fetchUserProfile()` → GET user name from Deezer API
- Credentials: placeholder (`YOUR_DEEZER_APP_ID`) — needs registration at developers.deezer.com

---

## Models

### `WorkoutPlaylist.swift`

Two structs for custom workout playlists:

```swift
WorkoutPhase
    - id: UUID
    - zone: HeartRateZone      // which BPM zone
    - targetTrackCount: Int     // how many songs desired
    - tracks: [SpotifyTrack]    // actual assigned songs

WorkoutPlaylist
    - id: UUID
    - name: String
    - phases: [WorkoutPhase]
    - createdAt / updatedAt: Date
    - allTracks: [SpotifyTrack]           // computed: all tracks across all phases
    - estimatedDuration: TimeInterval     // computed: sum of track durations
    - estimatedDurationText: String       // e.g., "12m 34s"
    - totalTrackCount: Int                // computed
    - phaseSummary: String                // e.g., "2 Warm-up → 3 Cardio → 1 Peak"
```

Both are `Codable` (for JSON persistence) and `Hashable` (for SwiftUI lists).

---

## Views

### `MainTabView.swift` — Tab Navigation

4-tab layout using SwiftUI `TabView`:

| Tab | View | Icon |
|-----|------|------|
| Home | HomeView | heart.fill |
| Playlists | PlaylistView | music.note.list |
| Workout | WorkoutView | figure.run |
| Profile | ProfileView | person.fill |

Tab bar tint follows `themeManager.currentTheme.accentColor`.

---

### `HomeView.swift` — Heart Rate Dashboard

The main screen showing real-time heart rate with an animated pulsing heart logo.

**Features:**
- **HeartLogoView** — animated heart+headphones that pulses at the user's heart rate
- Zone color changes based on BPM (blue → green → orange → red → purple)
- Pulse speed syncs to BPM: `60.0 / Double(currentBPM)` seconds per beat
- Heart rate display: current BPM + zone name
- "Use Real Data" toggle: switches between HealthKit data and simulated demo
- Demo mode: shows simulated calories, duration, workout status
- StatView cards for workout metrics
- Themed background gradient adapts to light/dark mode

**How zone colors are determined:**
```
0–89 BPM   → .blue   (Warm-up)
90–119 BPM → .green  (Fat Burn)
120–139 BPM→ .orange (Cardio)
140–159 BPM→ .red    (Peak)
160+ BPM   → .purple (Maximum)
```

---

### `PlaylistView.swift` — Music Library Browser

Displays the user's music organized by heart rate zone.

**Components:**

1. **Authenticated View** — shows tracks by zone
2. **Unauthenticated View** — prompts to connect Spotify/Apple Music
3. **ZoneSection** — one horizontal scroll per zone, with:
   - Zone name + BPM range
   - Track count
   - **Play Zone** button (plays all tracks in that zone as a queue)
   - Up to 10 TrackCards
4. **TrackCard** — 120x120 album art with:
   - AsyncImage for album artwork
   - Play/pause overlay button
   - Track name + artist below
   - Highlights current playing track
5. **NowPlayingBar** — floating bottom bar showing:
   - Album art thumbnail
   - Track name + artist
   - Queue position ("3 of 12") when in queue mode
   - "Preview" label when playing 30-sec preview
   - Previous/Play-Pause/Next/Stop controls
   - Green progress bar at top

---

### `WorkoutView.swift` — Custom Workout Playlists

Manages creation and playback of custom BPM-sequenced workout playlists.

**Layout:**
1. **Auto DJ Card** (top) — heart-rate-reactive playback
2. **Playlist List** (below) — user's custom workout playlists

**Auto DJ Card:**
- Shows heart rate, current zone, tracks played counter when active
- Start/Stop buttons
- Requires music to be loaded first

**WorkoutPlaylistRow:**
- Playlist name + estimated duration
- Phase pills showing zone colors and fill status (e.g., "2/3 Cardio")
- Action buttons: Play All, Randomize, Edit

**CreateWorkoutPlaylistView (sheet):**
- Name field
- Phase list with add/remove/reorder
- Add Phase opens AddPhaseSheet (zone picker + track count stepper)

**EditWorkoutPlaylistView (sheet):**
- Rename playlist
- Per-phase: zone info, target count stepper, track list
- Per-phase controls: play zone, shuffle to auto-fill
- Per-track: album art, name, artist, individual play button
- Swipe to delete tracks, drag to reorder phases

---

### `ProfileView.swift` — Settings & Connections

Service hub for managing all app integrations.

**Sections:**

1. **Music Services:**
   - Spotify (opens SpotifyLoginView sheet)
   - Apple Music (requests MusicKit authorization)
   - YouTube Music (opens Google OAuth in browser)
   - Deezer (opens Deezer OAuth in browser)

2. **Health & Fitness:**
   - HealthKit (requests permission)
   - Strava (opens OAuth in browser)
   - Location Services (requests permission)

3. **Theme:**
   - Horizontal scroll of 5 theme options
   - Each shows heart+headphones mini icon in the theme's color
   - Selected theme gets a colored ring indicator

4. **Settings:**
   - Notifications, Dark Mode, Units placeholder rows

**ServiceRow component:** Shows icon, title, status text, connect/disconnect button. Green checkmark when connected.

---

### `HeartLogoView.swift` — Animated Logo

The heart-with-headphones animated logo used on the Home screen.

**Visual layers (bottom to top):**
1. Radial gradient glow (pulsing scale + opacity)
2. Secondary stroke ring (pulsing)
3. Heart symbol with linear gradient fill + shadow glow
4. Headphones overlay (slightly offset upward)
5. Four orbiting beat indicator dots

**Customization:**
- `zoneColor: Color?` — overrides theme heart color (for BPM-based coloring)
- `scale: CGFloat` — size multiplier (1.0 = 280pt)
- `isPulsing: Bool` — enables/disables animation
- `pulseSpeed: Double` — seconds per beat

**HeartLogoCompact:** Simplified 28pt version for small UI areas.

**Dark/Light mode:** Headphone opacity and shadow intensity adapt to `colorScheme`.

---

### `SpotifyLoginView.swift` — Spotify Login Screen

OAuth entry point for Spotify.

- Feature list (Match music to heart rate, Organize by BPM, Discover new music)
- Green "Connect with Spotify" button → opens OAuth URL in system browser
- Pink "Connect with Apple Music" button (placeholder)
- Uses `@Environment(\.openURL)` to launch Safari

---

## Theme System

The theme affects these areas:
- **HomeView** — heart logo color, background gradient
- **MainTabView** — tab bar tint color
- **ProfileView** — theme picker UI
- **HeartLogoView** — heart color, headphone color, glow color

Each theme defines separate color palettes for light and dark mode via `backgroundGradientLight` and `backgroundGradientDark`. The `backgroundGradient(for:)` method returns the correct one based on the current `ColorScheme`.

---

## OAuth Flows

All OAuth integrations follow the same pattern:

1. **User taps Connect** → app calls `getAuthorizationURL()`
2. **System browser opens** → user authorizes on the service's website
3. **Service redirects** → `beatly://{host}?code=XXXX`
4. **iOS delivers URL** → `BeatlyApp.onOpenURL` routes to correct handler
5. **Handler extracts code** → calls `exchangeCodeForToken(code:)`
6. **Manager POSTs to token endpoint** → receives access token
7. **Token stored in memory** → manager's `isAuthenticated` becomes true

**Important:** Tokens are currently stored in memory only. They are lost when the app is terminated. Future improvement: persist tokens to Keychain.

---

## Music Playback System

```
User taps Play
       │
       ▼
PlaybackManager.play(track:)
       │
       ├──► trySpotifyApp(trackId:)
       │    └── Opens spotify:track:{id}  ──► Spotify app plays full song
       │         (if Spotify is installed)
       │
       └──► playPreview(url:)  (fallback)
            └── AVPlayer plays 30-sec preview
                 ├── Progress tracking via periodic time observer
                 └── End-of-track detection via notification
                      ├── Queue mode: auto-plays next track
                      └── Auto DJ mode: reads heart rate → picks next zone track
```

---

## Heart Rate & Health Integration

```
Apple Watch
    │ (writes heart rate samples)
    ▼
HealthKit Store (on iPhone)
    │
    ▼
HealthKitManager.startHeartRateMonitoring()
    │ (HKAnchoredObjectQuery — fires on every new sample)
    ▼
healthManager.currentHeartRate → Int
    │
    ├──► HomeView: updates heart color, zone label, pulse speed
    ├──► Auto DJ: determines which zone to pick next track from
    └──► WorkoutView: displayed in Auto DJ card
```

---

## Configuration Files

### `Info.plist`

| Key | Value | Purpose |
|-----|-------|---------|
| `CFBundleURLSchemes` | `["beatly"]` | Custom URL scheme for OAuth callbacks |
| `LSApplicationQueriesSchemes` | `["spotify", "spotify-action", "strava", "youtube", "youtube-music", "deezer"]` | Check if apps are installed |
| `NSAppleMusicUsageDescription` | Usage string | Apple Music permission prompt |
| `NSLocationWhenInUseUsageDescription` | Usage string | Location permission prompt |
| `UIBackgroundModes` | `["audio"]` | Allow background audio playback |

### `Beatly.entitlements`

| Key | Value |
|-----|-------|
| `com.apple.developer.healthkit` | `true` |

---

## How Everything Connects

```
┌─────────────────────────────────────────────────────┐
│                   BeatlyApp                          │
│  (creates all managers, injects via .environment())  │
│  (routes OAuth callbacks to correct manager)         │
└─────────────┬───────────────────────────────────────┘
              │
    ┌─────────┴─────────┐
    │   ContentView      │
    │   └── MainTabView  │
    │        ├── HomeView ──────── HealthKitManager (heart rate)
    │        │                     ThemeManager (colors)
    │        │                     └── HeartLogoView (animated)
    │        │
    │        ├── PlaylistView ──── SpotifyManager (tracks by zone)
    │        │                     PlaybackManager (play/pause)
    │        │                     └── NowPlayingBar
    │        │
    │        ├── WorkoutView ───── WorkoutPlaylistManager (CRUD)
    │        │                     PlaybackManager (queue + Auto DJ)
    │        │                     SpotifyManager (track pool)
    │        │                     HealthKitManager (heart rate for DJ)
    │        │
    │        └── ProfileView ───── All managers (connect/disconnect)
    │                              ThemeManager (theme picker)
    └─────────────────────────────┘
```

---

*Last updated: May 2026*
