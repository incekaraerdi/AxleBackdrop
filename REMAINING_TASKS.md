# AxleBackdrop - Remaining Tasks

**Current Status:** TestFlight v1.0.2 Live  
**Date:** 2026-11-16

---

## 🔴 CRITICAL (Before App Store)

### Vision Framework Quality Validation
- [ ] Test on 10+ real cars (various makes, colors, angles)
- [ ] Test on 10+ motorcycles (various types)
- [ ] Document segmentation success rate
- [ ] Identify edge cases (reflections, damaged panels, etc.)
- [ ] Decide: Use "AI" subtitle or just "Listing Photos"?
- [ ] Create VISION_QUALITY_REPORT.md

**Timeline:** 1 week (ongoing TestFlight feedback)

### Spatial Accuracy Fixes (v1.0.3)
- [ ] Fix vehicle floating issue (ground plane detection)
- [ ] Fix vehicle scale (too small)
- [ ] Fix perspective transformation
- [ ] Test improvements on real vehicles
- [ ] Performance baseline on iPhone 14

**Timeline:** 1 week (after TestFlight feedback)

### Camera Permission Testing (Real Device)
- [ ] Test camera capture on iPhone
- [ ] Test Photo Library picker
- [ ] Test permission denial flows
- [ ] Test permission re-request
- [ ] Test app interruption recovery

**Timeline:** 3 days (parallel with TestFlight)

---

## 🟡 HIGH PRIORITY (Before Public Beta)

### App Store Metadata - INCOMPLETE ⚠️
- [ ] **App Name** - Set (AxleBackdrop)
- [ ] **Subtitle** - PENDING (depends on Vision validation)
  - Option 1: "AI Car & Moto Listing Photos" (if validated)
  - Option 2: "Car & Moto Listing Photos" (safe)
- [ ] **Description** - Draft exists, needs finalization
- [ ] **Keywords** - Draft exists
- [ ] **Support URL** - PENDING (create support site or use email)
- [ ] **Privacy Policy URL** - PENDING (host HTML file)
- [ ] **Screenshots** - MISSING (need 5-6 per device type)
- [ ] **App Preview Video** - OPTIONAL (nice to have)

**Timeline:** 3-5 days

### External Testing Setup
- [ ] Create "Beta Testers" group (External Testing)
- [ ] Recruit 5-10 external testers
- [ ] Send invitations
- [ ] Monitor crashes/feedback
- [ ] Document issues

**Timeline:** After internal testing passes (3-5 days)

### Real Device Testing Checklist
- [ ] iPhone 16 Pro - Test all features
- [ ] iPhone 15 - Test performance
- [ ] iPhone 14 - Test on oldest supported
- [ ] Various lighting conditions
- [ ] Various vehicle types
- [ ] Various scene types
- [ ] Export quality verification

**Timeline:** 1 week (ongoing)

---

## 🟠 MEDIUM PRIORITY (Before v1.0.4)

### Performance Optimization
- [ ] Memory baseline on iPhone 14
- [ ] Battery impact measurement
- [ ] Processing time optimization
- [ ] Disk usage verification
- [ ] Network dependency check (should be zero)

**Timeline:** 2 weeks (post-beta)

### Additional Scene Types (Future)
- [ ] Add more backgrounds (beach, urban, etc.)
- [ ] Add day/night variations
- [ ] User-uploaded backgrounds (future)

**Timeline:** v1.0.4+

### Motorcycle-Specific Features (Future)
- [ ] Optimize for motorcycle angles
- [ ] Handle handlebar segmentation
- [ ] Test with various motorcycle types

**Timeline:** v1.0.4+

---

## 🟢 LOW PRIORITY (Nice-to-Have)

### Marketing Assets
- [ ] Real vehicle showcase photos
- [ ] How-to guide/tutorial
- [ ] Before/after examples
- [ ] Social media assets
- [ ] Press release draft

**Timeline:** Parallel with beta (optional)

### Documentation
- [ ] User manual
- [ ] FAQ page
- [ ] Troubleshooting guide
- [ ] Developer documentation (for future team)

**Timeline:** Post-launch

### Additional Languages
- [ ] Turkish localization (future)
- [ ] Other languages (future)

**Timeline:** v1.1+

---

## 📊 PHASE STATUS

### Phase 1: Critical Issues ✅ COMPLETE
- [x] Source photo integrity
- [x] Camera permission flows
- [x] Processing robustness
- [x] Vision confidence scoring
- [x] Distribution certificate
- [x] Archive signed
- [x] Build uploaded to App Store Connect
- [x] TestFlight live
- [x] GitHub documentation

### Phase 2: Real Device Validation 🔄 IN PROGRESS
- [ ] Vision quality validated (10+ cars, 10+ motorcycles)
- [ ] Spatial accuracy fixes (v1.0.3)
- [ ] Camera/permissions tested
- [ ] Performance baseline measured
- [ ] External testing launched
- [ ] App Store submission ready

### Phase 3: Monetization ❌ NOT STARTED
- [ ] RevenueCat integration
- [ ] Subscription products created
- [ ] Paywall UI implemented
- [ ] Feature gating functional
- [ ] Testing complete
- **Timeline:** After App Store launch

---

## 📅 TIMELINE TO APP STORE

### Week 1 (This Week)
- TestFlight internal testing
- Real device testing (camera, permissions)
- Identify v1.0.3 fixes needed
- **Status:** IN PROGRESS 🔄

### Week 2 (Next Week)
- Implement v1.0.3 fixes
- Test spatial accuracy improvements
- Vision quality validation starts
- **Status:** PENDING ⏳

### Week 3
- Finalize v1.0.3 release
- Create App Store metadata/screenshots
- Decision on "AI" subtitle
- Expand to external testing (optional)
- **Status:** PENDING ⏳

### Week 4
- App Store submission preparation
- Final review before submission
- **Status:** PENDING ⏳

### Week 5+
- App Store review (1-3 days)
- Approval and launch
- **Status:** PENDING ⏳

---

## 🎯 BLOCKERS

### Must Resolve Before App Store
1. **Spatial accuracy** - Vehicle floating/scaling issue
   - Impact: Quality concern for users
   - Effort: 2-3 days
   - Status: IN PROGRESS (testing to identify fixes)

2. **Vision quality validation** - Need real vehicle corpus data
   - Impact: Can't claim "AI" in subtitle without validation
   - Effort: 1 week of feedback collection
   - Status: IN PROGRESS (TestFlight beta)

3. **App Store metadata** - Support URL and Privacy Policy URL needed
   - Impact: Can't submit without these
   - Effort: 1-2 days
   - Status: PENDING ⏳

### Nice-to-Have (Can Skip for MVP)
- [ ] Screenshots (can use placeholder)
- [ ] Marketing materials
- [ ] Multiple language support
- [ ] Additional features

---

## 🔵 PHASE 3: MONETIZATION (Post-App Store)

### RevenueCat Integration - NOT STARTED ❌

**Prerequisites:**
- [ ] App must be on App Store first
- [ ] Real user feedback and metrics needed
- [ ] Pricing decision made

**Setup Tasks:**
- [ ] Create RevenueCat account
- [ ] Create subscription products (Free, Pro, Premium)
- [ ] Configure in App Store Connect
- [ ] Get RevenueCat API key

**Code Implementation:**
- [ ] Add RevenueCatManager.swift (actor pattern)
- [ ] Add PaywallView.swift (subscription UI)
- [ ] Add FeatureGating.swift (entitlement checks)
- [ ] Update ExportService for feature limits
- [ ] Add in-app purchase flow
- [ ] Add restore purchases button
- [ ] Add settings view subscription management

**Features to Gate:**
- [ ] Free tier: 5 listings/month
- [ ] Pro tier: Unlimited listings, priority processing
- [ ] Premium features (future): Batch processing, API access

**Testing Required:**
- [ ] Sandbox testing
- [ ] Purchase flow validation
- [ ] Restore purchases flow
- [ ] Subscription renewal testing
- [ ] RefreshData calls after purchase

**Timeline:** 2-3 weeks (AFTER App Store launch + user feedback)  
**Effort:** Medium (5-7 days development + 2 days testing)  
**Blocking:** No (can launch free-only first)

---

## 🚀 RECOMMENDED PRIORITY

### This Week (Critical Path)
1. TestFlight feedback collection
2. Real device camera/permissions testing
3. Vision quality assessment
4. Document v1.0.3 requirements

### Next Week
1. Implement v1.0.3 spatial fixes
2. Create App Store metadata
3. Take screenshots
4. Host privacy policy + support docs

### Week 3
1. Final testing
2. App Store submission
3. Monitor review process

---

## 📞 DEPENDENCIES

**On You:**
- Real vehicle testing feedback
- Vision quality assessment
- Camera/permission edge case testing
- Support URL setup
- Privacy policy hosting

**On Apple:**
- App Store review (1-3 days)
- TestFlight beta feedback (ongoing)

---

## 💡 QUICK WINS (Do Now)

1. **Host Privacy Policy**
   - Use GitHub Pages or simple domain
   - Point `privacyPolicy.html` there
   - Effort: 30 min

2. **Create Support Email**
   - Forward to your email
   - Effort: 15 min

3. **Plan v1.0.3 Fixes**
   - Document spatial issues
   - Prioritize by impact
   - Effort: 1 hour

---

**Last Updated:** 2026-11-16  
**Next Review:** 2026-11-18 (after 2 days TestFlight feedback)
