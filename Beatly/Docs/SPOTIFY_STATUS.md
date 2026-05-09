# Spotify Integration Status — April 29, 2026

## What Works
- Authentication (OAuth) is working with the new app credentials
- Search API (`/v1/search`) works in dev mode — currently used to load tracks
- Track display in PlaylistView with album art, artist names, zone organization

## What Doesn't Work (Yet)
- `GET /me/playlists` — returns 403 Forbidden
- `GET /me/tracks` (Saved/Liked Songs) — returns 403 Forbidden
- `GET /me/top/tracks` — returns 403 Forbidden
- Audio Features API (`/v1/audio-features`) — fully deprecated by Spotify

## Spotify Dev Mode Restrictions (Feb 2026)
- App owner must have Spotify Premium (Gabriel has Premium Duo)
- Limited to 5 test users
- Many endpoints restricted or removed
- Batch endpoints removed (must fetch individually)
- `/tracks` renamed to `/items` for playlist endpoints

## Credentials
- Client ID: `3e667d245f874478ab36c4070f7b40be`
- Client Secret: `ea55c05fe75d4fc4b4f1aacbc8ce9b44`
- Redirect URI: `beatly://callback`
- Owner email: gabriel.netto@gmail.com
- Test user: Gabriel Netto (gabriel.netto@gmail.com)

## Things to Try Next
1. **Try `GET /playlists/{playlist_id}`** — fetching a specific known playlist by ID
   might work even if `/me/playlists` doesn't
2. **Try `GET /users/{user_id}/playlists`** — alternative endpoint to list playlists
3. **Try the new generic library endpoints:**
   - `GET /me/library/contains` with Spotify URIs
   - `PUT /me/library` / `DELETE /me/library`
4. **Check if the Spotify Developer Dashboard owner account matches the login account**
   — the 403 might mean the logged-in user isn't the app owner
5. **Check Premium status** — try `GET /me` to see if Premium is confirmed
6. **Consider applying for Extended Quota** if personal library access is essential

## Current Workaround
Using Search API to load tracks by genre (pop, rock, hip hop, electronic, latin).
This works but doesn't show the user's personal music.

## Key Sources
- https://developer.spotify.com/documentation/web-api/concepts/quota-modes
- https://developer.spotify.com/documentation/web-api/tutorials/february-2026-migration-guide
- https://developer.spotify.com/documentation/web-api/references/changes/february-2026
