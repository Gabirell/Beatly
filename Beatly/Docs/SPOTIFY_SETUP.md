# Spotify Integration Setup Guide

## Prerequisites

Before integrating Spotify, you need:

1. ✅ **Spotify Developer Account** - Free at https://developer.spotify.com
2. ✅ **Client ID and Client Secret** - From your Spotify app dashboard
3. ✅ **Redirect URI** - Set to `beatly://callback`

---

## Step 1: Add Spotify SDK

We'll use **Swift Package Manager** to add the Spotify SDK.

### Add Package Dependency:

1. **In Xcode, go to:** File → Add Package Dependencies...
2. **Enter URL:** `https://github.com/spotify/ios-sdk`
3. **Dependency Rule:** Up to Next Major Version (1.0.0)
4. **Click "Add Package"**
5. **Select "SpotifyiOS"** from the list
6. **Click "Add Package"**

---

## Step 2: Configure Info.plist

### Add URL Scheme

Your app needs to handle the Spotify redirect callback.

1. **Open Info.plist**
2. **Add these keys:**

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>beatly</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.beatly</string>
    </dict>
</array>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>spotify</string>
    <string>spotify-action</string>
</array>
```

Or using the Xcode interface:

**URL Types:**
1. Click "+" under "URL Types"
2. **Identifier:** `com.yourcompany.beatly`
3. **URL Schemes:** `beatly`

**Queried URL Schemes:**
1. Add new item: `spotify`
2. Add new item: `spotify-action`

---

## Step 3: Understanding Spotify API Endpoints

### Key Endpoints We'll Use:

1. **Authorization**
   ```
   GET https://accounts.spotify.com/authorize
   ```
   - Gets user permission to access their data

2. **Get User's Top Tracks**
   ```
   GET https://api.spotify.com/v1/me/top/tracks
   ```
   - Returns user's most played songs

3. **Get Track Audio Features**
   ```
   GET https://api.spotify.com/v1/audio-features/{id}
   ```
   - Returns BPM (tempo), energy, danceability, etc.

4. **Search Tracks**
   ```
   GET https://api.spotify.com/v1/search?q=genre:rock+tempo:120-140
   ```
   - Search for songs by BPM range

5. **Get Recommendations**
   ```
   GET https://api.spotify.com/v1/recommendations?seed_tracks={ids}&target_tempo=120
   ```
   - Get song recommendations based on BPM

---

## Understanding BPM in Spotify

### Audio Features Response Example:

```json
{
  "tempo": 120.0,        // ← BPM (beats per minute)
  "energy": 0.8,         // How energetic (0.0 to 1.0)
  "danceability": 0.7,   // How danceable
  "valence": 0.6,        // How positive/happy
  "duration_ms": 240000  // Song length
}
```

### BPM Zones for Workouts:

| Zone | BPM Range | Exercise Type |
|------|-----------|---------------|
| Warm-up | 60-90 | Light walking, stretching |
| Fat Burn | 90-120 | Walking, light jogging |
| Cardio | 120-140 | Running, cycling |
| Peak | 140-160 | Intense cardio, HIIT |
| Maximum | 160+ | Sprinting, max effort |

---

## Step 4: Create Your Spotify Manager

I'll create a `SpotifyManager.swift` file that handles:
- Authentication
- API requests
- BPM analysis
- Playlist creation

---

## Security Note

**NEVER commit your Client Secret to Git!**

We'll use environment variables or a config file to store sensitive data.

---

## What's Next?

After you:
1. ✅ Create Spotify Developer Account
2. ✅ Get Client ID and Client Secret
3. ✅ Set up Redirect URI as `beatly://callback`

I'll help you:
1. Create the Spotify Manager
2. Implement authentication
3. Fetch and analyze songs by BPM
4. Match music to heart rate zones

---

**Are you ready to:**
- Create your Spotify Developer account?
- Get your Client ID and Client Secret?
- Let me know when you have them (don't share the secret publicly!)

Then we can start coding the Spotify integration! 🎵🚀
