# HealthKit Setup Instructions

## Step 1: Add HealthKit Capability

1. **Open your project settings:**
   - Click on the blue "Beatly" project icon at the top of the Project Navigator
   - Select the "Beatly" target under "TARGETS"

2. **Add HealthKit capability:**
   - Click on the "Signing & Capabilities" tab
   - Click the "+ Capability" button
   - Search for "HealthKit"
   - Double-click "HealthKit" to add it

You should now see "HealthKit" in your capabilities list!

---

## Step 2: Add Privacy Usage Description

HealthKit requires you to explain WHY you need access to health data.

### Option A: Using Xcode Interface (Easier)

1. **Find Info.plist:**
   - In the Project Navigator, look for a file called `Info.plist`
   - Or select your target → "Info" tab

2. **Add the privacy key:**
   - Hover over any row and click the "+" button
   - Type: `Privacy - Health Share Usage Description`
   - Value: `Beatly needs access to your heart rate to sync music with your workout intensity.`

3. **Add another key:**
   - Click "+" again
   - Type: `Privacy - Health Update Usage Description`  
   - Value: `Beatly needs to save workout data to track your progress.`

### Option B: Edit Info.plist as Source Code

If you prefer to edit the raw XML:

1. Right-click on `Info.plist` → "Open As" → "Source Code"
2. Add these lines inside the `<dict>` tags:

```xml
<key>NSHealthShareUsageDescription</key>
<string>Beatly needs access to your heart rate to sync music with your workout intensity.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>Beatly needs to save workout data to track your progress.</string>
```

---

## Step 3: Test on a Real Device

**Important:** HealthKit does NOT work in the iOS Simulator!

You have two options:

### Option 1: Use a Real iPhone + Apple Watch
- Build and run on your actual iPhone
- Make sure your Apple Watch is paired
- The app will read real heart rate data!

### Option 2: Use Simulated Data (for now)
- Keep using the demo mode we built
- When you get a real device, the real data will work automatically

---

## Verification Checklist

✅ HealthKit capability added in Signing & Capabilities  
✅ Privacy descriptions added to Info.plist  
✅ Project builds without errors  
✅ (Optional) Tested on real device with Apple Watch  

---

## Troubleshooting

**"HealthKit is not available as a capability"**
- Make sure you're signed in with your Apple ID in Xcode
- Check that your bundle identifier is unique

**"Missing Privacy Usage Description"**
- Make sure you added both privacy keys to Info.plist
- Check for typos in the key names

**"No heart rate data"**
- HealthKit only works on real devices
- Make sure Apple Watch is paired and you've granted permissions
- Try doing some activity to generate heart rate data

---

*After completing these steps, come back to continue with the code integration!*
