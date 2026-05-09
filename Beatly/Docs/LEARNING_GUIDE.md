# Beatly App Development Guide
**Building Your First iOS App with SwiftUI**
Created: April 10, 2026

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [What We've Built So Far](#what-weve-built-so-far)
3. [SwiftUI Basics - Learning Guide](#swiftui-basics)
4. [Current File Structure](#current-file-structure)
5. [How to Test Your App](#how-to-test-your-app)
6. [Next Steps](#next-steps)
7. [Troubleshooting](#troubleshooting)

---

## Project Overview

**Beatly** is an iOS fitness app that syncs music BPM (beats per minute) with your heart rate during workouts.

### Main Features:
- ✅ Real-time heart rate monitoring from Apple Watch
- ✅ Music playlists organized by BPM (via Spotify)
- ✅ Custom workout planning with effort phases
- ✅ Location-aware safety features
- ✅ Social features (leaderboards, sharing routes)
- ✅ Gamification with contests

### Technology Stack:
- **Language:** Swift
- **Framework:** SwiftUI
- **APIs:** HealthKit, WorkoutKit, Spotify API, Location Services
- **Platform:** iOS (iPhone & Apple Watch)

---

## What We've Built So Far

### Phase 1A: Basic App Structure ✅ COMPLETE

We've created the foundation of your app with a tab-based navigation system and placeholder screens.

#### Files Created:

1. **MainTabView.swift** - Main navigation hub with 4 tabs
2. **HomeView.swift** - Main screen (will show pulsing heart + BPM)
3. **PlaylistView.swift** - Music playlists organized by BPM
4. **WorkoutView.swift** - Exercise planning and tracking
5. **ProfileView.swift** - User settings and connections
6. **ContentView.swift** - Entry point (updated to use MainTabView)

---

## SwiftUI Basics - Learning Guide

### 1. What is SwiftUI?

SwiftUI is Apple's modern framework for building user interfaces. Instead of writing separate code files for how things look, you describe your UI using Swift code, and SwiftUI handles the rest.

**Key Principle:** You declare WHAT you want to see, not HOW to draw it.

---

### 2. Views - The Building Blocks

Every screen element is a **View**. Views are structs that conform to the `View` protocol.

```swift
struct MyView: View {
    var body: some View {
        Text("Hello, World!")
    }
}
```

**Important Concepts:**
- `struct` = A lightweight container for data
- `View` = A protocol that requires a `body` property
- `body` = What actually appears on screen
- `some View` = Swift's way of saying "this returns a view, but I don't need to specify which type"

---

### 3. Layout Containers

These organize how views are arranged on screen:

#### VStack (Vertical Stack)
Arranges views from top to bottom.

```swift
VStack {
    Text("First")
    Text("Second")
    Text("Third")
}
```

#### HStack (Horizontal Stack)
Arranges views from left to right.

```swift
HStack {
    Image(systemName: "star")
    Text("Rating")
}
```

#### ZStack (Depth Stack)
Overlays views on top of each other.

```swift
ZStack {
    Circle()
        .fill(.blue)
    Text("On Top")
}
```

---

### 4. Modifiers

Modifiers change how views look or behave. They chain together with dots.

```swift
Text("Hello")
    .font(.title)           // Make text bigger
    .foregroundStyle(.red)  // Make text red
    .padding()              // Add space around it
```

**⚠️ Order matters!**

```swift
Text("Example")
    .padding()      // Adds padding first
    .background(.blue)  // Then adds blue background to the padded area
```

vs.

```swift
Text("Example")
    .background(.blue)  // Adds blue background to text only
    .padding()          // Then adds padding around it
```

---

### 5. Navigation

#### TabView
Creates tabs at the bottom of the screen (like Instagram or Apple Music).

```swift
TabView {
    HomeView()
        .tabItem {
            Label("Home", systemImage: "house")
        }
    
    SettingsView()
        .tabItem {
            Label("Settings", systemImage: "gear")
        }
}
```

#### NavigationStack
Creates hierarchical navigation (screens that push and pop).

```swift
NavigationStack {
    List {
        NavigationLink("Detail 1") {
            DetailView()
        }
    }
    .navigationTitle("Main")
}
```

---

### 6. Common SwiftUI Components

#### Text
Displays text on screen.

```swift
Text("Hello, World!")
    .font(.title)
    .bold()
```

#### Image
Displays images (from assets or SF Symbols).

```swift
// System icon
Image(systemName: "heart.fill")

// Your own image (in Assets catalog)
Image("myImage")
```

#### Button
Creates tappable buttons.

```swift
Button("Click Me") {
    print("Button tapped!")
}

// Or with custom label
Button {
    print("Tapped!")
} label: {
    Label("Save", systemImage: "checkmark")
}
```

#### List
Creates scrollable lists (like Settings app).

```swift
List {
    Text("Item 1")
    Text("Item 2")
    Text("Item 3")
}
```

---

### 7. State Management

SwiftUI is **declarative** - the UI automatically updates when data changes.

#### @State
For simple local values that can change.

```swift
struct CounterView: View {
    @State private var count = 0
    
    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button("Increment") {
                count += 1  // UI updates automatically!
            }
        }
    }
}
```

**Key Points:**
- Use `@State` for simple values owned by this view
- Mark as `private` - only this view should modify it
- When state changes, SwiftUI redraws the view

### 8. Timers in Swift

Timers let you run code repeatedly at specific intervals - perfect for animations or updating data.

```swift
// Create a timer that fires every 2 seconds
timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
    print("This runs every 2 seconds!")
}

// Don't forget to stop it when you're done!
timer?.invalidate()
```

**Important:** Always invalidate timers when you're done with them to prevent memory leaks!

### 9. String Formatting

Format numbers and text with `String(format:)` for precise control.

```swift
// Format time as MM:SS
let minutes = 5
let seconds = 7
let formatted = String(format: "%02d:%02d", minutes, seconds)
// Result: "05:07"

// %02d means: "integer with at least 2 digits, pad with zeros"
```

### 10. Switch Statements with Ranges

Use ranges in switch statements for elegant conditional logic.

```swift
var heartColor: Color {
    switch currentBPM {
        case 0..<60: return .blue        // 0 to 59
        case 60..<100: return .green     // 60 to 99
        case 100..<140: return .orange   // 100 to 139
        default: return .red             // 140 and above
    }
}
```

**Syntax:**
- `0..<60` = Range from 0 up to (but not including) 60
- `0...60` = Range from 0 up to and including 60

---

## What We Built in Phase 1B

### Features Added to HomeView:

1. **Pulsing Heart Animation** 💓
   - Heart scales up and down smoothly
   - Outer glow ring for depth
   - Animation speed syncs with BPM (faster heart = faster pulse)

2. **Dynamic Color System** 🎨
   - Blue: Very low/resting (<60 BPM)
   - Green: Normal resting (60-100 BPM)
   - Orange: Moderate cardio (100-140 BPM)
   - Red: Intense exercise (140-170 BPM)
   - Purple: Maximum effort (170+ BPM)

3. **Interactive Demo Simulation** 🎮
   - "Start Demo" button to test the app
   - Heart rate changes randomly (simulating exercise)
   - Calories and duration update in real-time
   - Heart color changes based on intensity

4. **Smooth Animations** ✨
   - Pulse animation syncs with actual BPM
   - Color transitions are smooth and gradual
   - Numbers count up smoothly with `.contentTransition(.numericText())`

### Key Code Patterns Used:

**@State for Reactive UI:**
```swift
@State private var currentBPM = 72  // When this changes, UI updates!
```

**Computed Properties for Logic:**
```swift
var heartColor: Color {
    switch currentBPM {
        case 60..<100: return .green
        // Automatically recalculates when currentBPM changes
    }
}
```

**Animations:**
```swift
.animation(
    .easeInOut(duration: pulseSpeed)
    .repeatForever(autoreverses: true),
    value: isPulsing
)
```

**Timers:**
```swift
timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
    // Update data every 2 seconds
}
```

---

## Current File Structure

```
Beatly/
├── BeatlyApp.swift           # App entry point (@main)
├── ContentView.swift         # Shows MainTabView
├── MainTabView.swift         # Tab navigation (4 tabs)
│
├── Views/
│   ├── HomeView.swift        # Pulsing heart screen
│   ├── PlaylistView.swift   # Music playlists by BPM
│   ├── WorkoutView.swift    # Exercise planning
│   └── ProfileView.swift    # Settings & connections
│
└── LEARNING_GUIDE.md         # This file!
```

---

## How to Test Your App

### Option 1: Live Preview (Fastest)
1. Open any view file (e.g., `HomeView.swift`)
2. Press `⌘ + Option + Return` to show Canvas
3. Click "Resume" if preview is paused
4. You'll see a live preview of that screen!

### Option 2: Simulator
1. Select a simulator device (e.g., "iPhone 15 Pro")
2. Press `⌘ + R` to build and run
3. Wait for simulator to launch
4. Your app will open automatically!

### Option 3: Real Device
1. Connect your iPhone via USB
2. Select your device from the device menu
3. Press `⌘ + R`
4. You may need to trust your developer certificate in Settings

---

## Next Steps

Here's your development roadmap:

### ✅ Phase 1A: Basic Structure (COMPLETE!)
- [x] Create main navigation
- [x] Build placeholder screens
- [x] Set up project structure

### ✅ Phase 1B: Visual Polish (COMPLETE!)
- [x] Add pulsing heart animation to HomeView
- [x] Improve UI with colors and styling
- [x] Add heart rate zones with color coding
- [x] Add interactive demo simulation
- [x] Add dynamic stats display

### 📋 Phase 2: Data Models
- [ ] Create models for: Playlist, Song, Workout, User
- [ ] Set up sample data for testing

### 🔄 Phase 3: HealthKit Integration (NEXT)
- [ ] Request health permissions
- [ ] Read real-time heart rate
- [ ] Display BPM on HomeView
- [ ] Calculate heart rate zones

### 🎵 Phase 4: Spotify Integration
- [ ] Set up Spotify Developer account
- [ ] Add Spotify SDK
- [ ] Authenticate user
- [ ] Fetch user's top tracks
- [ ] Analyze BPM of songs

### 🏃 Phase 5: Workout Features
- [ ] Create workout plan builder
- [ ] Start/stop workout tracking
- [ ] Match music to heart rate zones
- [ ] Save workout history

### 📍 Phase 6: Location & Safety
- [ ] Request location permissions
- [ ] Track workout routes
- [ ] Analyze terrain difficulty
- [ ] Safety alerts for busy areas

### 🏆 Phase 7: Social & Gamification
- [ ] User profiles
- [ ] Friend system
- [ ] Leaderboards
- [ ] Share routes and playlists

---

## Troubleshooting

### Common Issues and Solutions

#### "Cannot find 'MainTabView' in scope"
**Problem:** Xcode can't find your file.
**Solution:** 
1. Make sure the file is in your project navigator (left sidebar)
2. Check that it's included in your app target
3. Clean build folder: `⌘ + Shift + K`, then rebuild: `⌘ + B`

#### Preview Not Working
**Problem:** Canvas shows error or won't load.
**Solution:**
1. Press `⌘ + Option + Return` to toggle canvas
2. Click "Resume" button in canvas
3. Try `⌘ + Option + P` to refresh preview
4. If still broken, restart Xcode

#### Build Errors
**Problem:** Red errors in your code.
**Solution:**
1. Read the error message carefully
2. Click on the error to see which line has the problem
3. Common fixes:
   - Missing import (add `import SwiftUI` at top)
   - Missing closing brace `}`
   - Typo in variable or function name

#### Simulator Won't Launch
**Problem:** Simulator is stuck or won't open.
**Solution:**
1. Quit simulator: `⌘ + Q`
2. In Xcode: Device → Erase All Content and Settings
3. Try running again

---

## Key SwiftUI Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘ + R` | Build and Run |
| `⌘ + B` | Build |
| `⌘ + Shift + K` | Clean Build Folder |
| `⌘ + Option + Return` | Toggle Canvas |
| `⌘ + Option + P` | Refresh Preview |
| `⌘ + Click` | Show code actions menu |
| `Option + Click` | Show documentation |
| `⌘ + Shift + L` | Show library (views, modifiers, etc.) |

---

## Learning Resources

### Apple Official Documentation
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [HealthKit Documentation](https://developer.apple.com/documentation/healthkit)

### Recommended Practice
1. **Modify the existing views** - Change colors, text, layouts
2. **Add new UI elements** - Try adding buttons, images, etc.
3. **Experiment with modifiers** - See what different modifiers do
4. **Break things!** - The best way to learn is to see what happens when you change code

---

## Questions to Consider

As you develop, think about:

1. **User Experience**
   - How do users navigate between screens?
   - Is it clear what each button does?
   - Can users recover from mistakes?

2. **Performance**
   - Will real-time heart rate monitoring drain battery?
   - How do we handle poor network connection?
   - What if Spotify is slow to respond?

3. **Safety**
   - How do we alert users if heart rate is dangerously high?
   - What if location permissions are denied?
   - How do we protect user privacy?

---

## Notes and Ideas

(Use this space to write your own notes as you learn!)

---

**Remember:** Every expert was once a beginner. Don't be afraid to experiment, break things, and ask questions. You're doing great! 🚀

---

*Last Updated: April 10, 2026*
*Created by: Gabriel Netto with AI assistance*
