# App Store Connect Setup for TestFlight

**Build:** AxleBackdrop v1.0.2 (Build 2)  
**Archive:** `/tmp/AxleBackdrop_v1.0.2.xcarchive`  
**Date:** 2026-11-16

---

## Step 1: Create App Record (if not exists)

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Click "Apps" → "Create an App"
3. Fill:
   - **Platform:** iOS
   - **App Name:** AxleBackdrop
   - **Primary Language:** English
   - **Bundle ID:** com.rdcorp.AxleBackdrop
   - **SKU:** axlebackdrop-01
   - **User Access:** Full Access

---

## Step 2: Upload Build

### Option A: Via Transporter (Recommended)
```bash
# Download Transporter from App Store
# Open Transporter
# Drag-drop: /tmp/AxleBackdrop_v1.0.2.xcarchive
# Sign and deliver
```

### Option B: Via Xcode
```bash
cd /Users/rdcorp/Developer/IOS/Apps/AxleBackdrop/AxleBackdrop
xcodebuild -exportArchive -archivePath /tmp/AxleBackdrop_v1.0.2.xcarchive \
  -exportOptionsPlist exportOptions.plist \
  -exportPath /tmp/export
```

---

## Step 3: Fill App Metadata

### App Information
1. **App Name:** AxleBackdrop
2. **Subtitle:** AI Car & Moto Listing Photos *(or "Car & Moto Listing Photos" if Vision not validated)*
3. **Category:** Photography
4. **Content Rating:** Tap to fill questionnaire

### Description
```
Compose stunning vehicle listing photos in minutes.

Take 5 photos of your car or motorcycle, and AxleBackdrop 
intelligently extracts the vehicle and composites it onto 
professional backgrounds. Perfect for dealers and private sellers.

Features:
• Smart vehicle extraction using advanced vision
• Professional background compositing
• Export high-resolution JPEGs
• Local processing - photos never leave your device
• Support for cars and motorcycles

No subscription. No hidden fees. One-time use, perfect results.
```

### Keywords
`vehicle, car, motorcycle, photo, listing, composite, ai, photography, export`

### Support URL
```
https://axlebackdrop.app/support
```

### Privacy Policy URL
**Option 1 (Recommended for now):**
Leave blank in TestFlight, add after launch if needed.

**Option 2 (If hosting available):**
Upload privacy-policy.html to your domain:
```
https://axlebackdrop.app/privacy
```

**Option 3 (App Store - In-App):**
Add as in-app message (Settings view already has placeholder)

---

## Step 4: App Preview & Screenshots

### Recommended Screenshot Set
Use existing from QA/Screenshots/:

**iPhone 6.7-inch Display:**
1. Home screen (empty)
2. Vehicle type selection
3. Photos capture view
4. Scene selection
5. Processing screen
6. Export result

**Text Overlays:**
- "Create a Listing"
- "Choose Photos"  
- "Pick Scene"
- "AI Composites"
- "Save to Photos"

---

## Step 5: Build Selection

1. Go to TestFlight tab
2. Click "Build" section
3. Select: `AxleBackdrop v1.0.2 (Build 2)`
4. Fill TestFlight information (see below)

---

## Step 6: TestFlight Internal Testers

### Create Internal Testing Group
1. Click "TestFlight" tab
2. Click "Internal Testing"
3. Click "Create New Group" (or use default)
4. Add testers:
   - Your email (erdi.incekara@remed.com.tr)
   - Team members (if any)

### Internal Tester Instructions
```
Thank you for testing AxleBackdrop v1.0.2!

This beta includes critical fixes:
✅ Source photo backup & recovery
✅ Camera permission handling
✅ Processing safety limits

Please test:
1. Launch and create a listing
2. Capture 5 vehicle photos
3. Select a scene and process
4. Export to Photos

Expected time: 5-10 minutes per listing

Known limitations:
- Segmentation validated on test images only
- Real device camera testing (feedback welcome)
- Performance baseline on iPhone 17e

Report issues via TestFlight Feedback button.
```

---

## Step 7: TestFlight External Testers (After Internal Passes)

### Create External Testing Group
1. Click "TestFlight" tab
2. Click "External Testing"
3. Click "Create New Group" (name: "Beta Testers")
4. Add invited testers (get list from team)
5. Requires Apple review (~24-48 hours)

### External Tester Instructions
```
🎉 You're invited to AxleBackdrop Beta!

AxleBackdrop helps you create professional vehicle listing photos 
in minutes. Take 5 photos, select a background, and let AI do the rest.

✅ NEW in v1.0.2:
- Better photo preservation
- Smoother permission handling  
- More reliable processing

📱 How to test:
1. Take 5 photos of a vehicle
2. Choose Indoor Garage or Outdoor Scenic background
3. Let it process (~30-60 seconds)
4. Check the result
5. Export to Photos

⏱️ Time commitment: 10-15 minutes per vehicle

🐛 Found a bug? Use TestFlight > Feedback to report.

Questions? Email support@axlebackdrop.app

Thank you for helping us improve AxleBackdrop!
```

---

## Step 8: Enable TestFlight Build

1. Click the build under "Builds Available for Testing"
2. Toggle "Add for Testing" → ON
3. Save

---

## Step 9: Monitor TestFlight

Check daily:
- **Crashes:** TestFlight → Crashes (should be near 0%)
- **Feedback:** In-app or email to support@axlebackdrop.app
- **Install Rate:** How many are actually testing
- **Session Duration:** How long people use the app

---

## Support Email Setup

### At support@axlebackdrop.app
Create mail forwarding rule to: erdi.incekara@remed.com.tr

Or use simple responder:
```
Thank you for contacting AxleBackdrop support.

We're in active beta testing. Your feedback helps us improve!

Expected response: 48 hours

Best regards,
AxleBackdrop Team
```

---

## Timeline

- **Day 1 (Today):** Upload build, internal testing begins
- **Day 2-3:** Internal QA, fix any critical issues
- **Day 3:** Submit external testing for Apple review
- **Day 5:** Apple approves, external testers invited
- **Day 7-14:** Collect feedback, plan v1.0.3
- **Week 3:** v1.0.3 release with improvements

---

## Troubleshooting

### "Build not appearing in TestFlight"
- Wait 5-10 minutes for processing
- Check build status in "Builds" section
- Ensure version matches (1.0.2, Build 2)

### "Can't add external testers"
- Need 10+ internal testers first (Apple policy)
- Wait for internal testing completion
- Submit external test group for Apple review

### "Privacy Policy URL needed for App Store"
- Can leave blank for TestFlight
- Will need URL before App Store submission
- Options: GitHub Pages, custom domain, in-app text

---

## Next: After TestFlight Feedback

Once you have 1-2 weeks of beta feedback:
- Plan v1.0.3 improvements
- Validate Vision quality on real vehicles
- Test memory/battery on iPhone 14
- Prepare App Store listing assets

Then ship to App Store! 🚀

---

**Ready?** All commands are ready. Let me know when you need help uploading.
