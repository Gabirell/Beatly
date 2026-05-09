//
//  CLAUDE.md
//  Beatly
//
//  Created by Gabriel Netto on 10/04/26.
//

App Beatly (Before - Sportify)

1. Setup a playlist that matches bpm with cardiac rhythmic realtime or plan music for a sequence of exercises. It should read iWatch Exercise app (or others like it Health or Sport kit) to follow realtime exercise/health data.
2. Apis needed: Spotify, SportKit, Random user for testing
3. Use Figma or other free service like whisk, canvas, etc for design
4. Get most listened music from user
5. Search for similar style and bpms.
6. Add a geolocation kit to be aware of where is the exercise being made: gym, swimming pool, sea, lake, running in the city, in the countryside, etc. The objective is to preview if the path is going to have more or less difficulty, if there is a danger (streets in a city, for example) where hearing music too loud can be dangerous, etc.
7. Gamify the experience with contests with other users, share playlists synced and share routes and locations with family or close friends for security (when outside)


PLAN:
**App Overview:**
App Beatly is an iOS app built using Xcode and Swift UI that aims to provide a personalized music experience for users during their workouts. The app will:

1. Setup a playlist that matches the user's cardiac rhythmic realtime or plan music for a sequence of exercises.
2. Integrate with Spotify API to access the user's music library and preferences.
3. Utilize SportKit API to track the user's workouts and exercises.
4. Use Figma for designing the app's UI/UX.
5. Fetch the user's most listened music and search for similar style and bpms to create a personalized playlist.

**Technical Requirements:**

* Xcode: 13.4 or later
* Swift UI: 2.0 or later
* Spotify API: Web API (RESTful API)
* SportKit API: iOS 14 or later
* Figma: For designing the app's UI/UX
* Random User API: For testing purposes

**API Integrations:**

* Spotify API:
    + Get user's most listened music
    + Search for similar music based on style and bpms
    + Create a playlist with the selected music
* SportKit API:
    + Track user's workouts and exercises
    + Get user's cardiac rhythmic data
* Random User API:
    + Fetch random user data for testing purposes
* Apple Maps (or findmyphone) API:
    + To voluntarily share where the user is and to calculate possible efforts in the map like steep streets, stairs, etc for     calculations of effort distribution.

**Figma Design, Whisk or others:**
 Figma design for the app's UI/UX. Please let me know what kind of design you're looking for (e.g., minimalistic, modern, etc.).

**Next Steps:**
Before we begin, I'd like to confirm the following:

DESIGN:

FIRST LOGIN:
1. Welcome screen: Configuring Spotify (or other music services - from now on I will use only Spotify as reference for any music service)
2. Get health data (weight, height etc and calculations to keep healthy and progressive effort evolution.
Sync with user’s Spotify preferred songs, music styles and heart beat
Read favorites and organize favorites by BPM  3. Create a My Music list and a Discover one with music the user could like.  
Create list button: Let user make a custom selection of music, save and arrange them. Effort plan: Creation of effort routine, organizing and programing exercise sessions: for example, 5 minutes of slow cardio (slower bpms) then 10 minutes of  some harder  effort (loads faster bps) and 25 of harder effort (faster bps) and 5 minutes to get to slower bpms.  

UI:
1. The main screen will have a big pulsing heart using headphones with the bpm of the heart in the middle. Search for battery issues and how to make it low consumption. Alert if heart rate is too high
2. While making exercises, show calories, change the heart color by effort.
3. Exercises.


