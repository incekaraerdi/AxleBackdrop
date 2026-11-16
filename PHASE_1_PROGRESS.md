# Phase 1: Critical Fixes - Progress Report

**Date:** 2026-11-16  
**Status:** Issue 1 core implementation ✅ complete; Issue 2–4 ready to begin

---

## Issue 1: Source Photo Integrity ✅ (95% Complete)

### What Was Fixed
- ✅ Separated raw source photos from normalized display versions
- ✅ Byte-for-byte preservation of original photos
- ✅ Metadata tracking (dimensions, orientation)
- ✅ Backward compatibility with existing display code
- ✅ Processing pipeline updated to use source files
- ✅ 3 new unit tests added for validation

### Files Modified
1. **Models.swift** — PhotoRecord structure enhanced with source metadata
2. **PhotoFileStore.swift** — storeOriginal() now returns source + normalized filenames
3. **PhotosView.swift** — Updated to store both filenames and metadata
4. **SceneAndProcessingViews.swift** — ProcessingView uses sourceFilename for processing
5. **AxleBackdropTests.swift** — Added testSourceFilePreservation() + testSourceMetadataPreservation()

### Build Status
- ✅ Compiles successfully (no errors or warnings)
- ✅ All existing imports and dependencies work
- ⏳ Unit tests running on iPhone 17e simulator (iOS 26.4)

### Storage Structure
```
~/Library/Application Support/AxleBackdrop/Drafts/{id}/Originals/
├── slot-1-source.jpg        ← Raw bytes (original photo)
├── slot-1-original.jpg      ← 4:3 normalized (display)
├── slot-2-source.jpg
└── slot-2-original.jpg
```

### Backward Compatibility
- Display code (PhotosView, SceneView, etc.) unaffected
- Existing drafts continue to work (uses originalFilename)
- New drafts store both versions for future enhancements

### Test Coverage
**Implemented:**
- testSourceFilePreservation() — Verifies byte-exact storage
- testSourceMetadataPreservation() — Checks metadata recording
- testFiveJPEGExportOrderSizeAndMetadata() — Updated existing test

**Status:** Tests executing, results pending

---

## Issue 2: Vision Quality Validation — Ready to Begin

### Requirement
Validate `VNGenerateForegroundInstanceMaskRequest` segmentation on real vehicles

### To-Do
- [ ] Create VALIDATION_CORPUS.md documenting photo requirements
- [ ] Add confidence scoring to ImageProcessingService.renderExterior()
- [ ] Implement fallback logic (use original if confidence < 0.75)
- [ ] Add confidence badge to ProcessingView UI
- [ ] Run corpus through pipeline with user's 10+ car + 10+ motorcycle photos
- [ ] Document results in VISION_QUALITY_REPORT.md
- [ ] Decide on "AI" subtitle (only if ≥95% pass)

### Key Files
- `ImageProcessingService.swift` — Add confidence threshold
- `SceneAndProcessingViews.swift:ProcessingView` — Show confidence badge
- `VALIDATION_CORPUS.md` — Document requirements
- `VISION_QUALITY_REPORT.md` — Results after testing

**Critical:** Don't use "AI" subtitle until corpus validated.

---

## Issue 3: Camera & Permission Flows — Ready to Begin

### Requirement
Real device testing for camera capture, permissions, and recovery

### To-Do
- [ ] Add explicit camera availability check in PhotosView
- [ ] Implement permission status caching + foreground refresh
- [ ] Add graceful fallback (Photo Library button if no camera)
- [ ] Add app lifecycle observers to AxleBackdropApp
- [ ] Implement draft state recovery on resume
- [ ] Create DEVICE_TESTING_CHECKLIST.md
- [ ] Add UI tests for permission denial scenarios
- [ ] Manual test on iPhone 16, 15 Pro, and 14

### Key Files
- `PhotosView.swift` — Camera availability check
- `AxleBackdropApp.swift` — Lifecycle observers + recovery
- `AxleBackdropUITests.swift` — Permission flow tests
- `DEVICE_TESTING_CHECKLIST.md` — Physical device steps

**Priority:** Must test on iPhone 16, 15/15 Pro, 14 before TestFlight

---

## Issue 4: Processing Robustness & Memory — Ready to Begin

### Requirement
Handle edge cases: low memory, disk full, cancellation, timeout

### To-Do
- [ ] Add max input resolution limit (4000×3000)
- [ ] Implement memory warning handler
- [ ] Add per-photo timeout (30 seconds)
- [ ] Pre-flight disk space check (100 MB free)
- [ ] Cleanup of orphaned temp files on startup
- [ ] Cancellation token + graceful shutdown in ProcessingView
- [ ] Add tests: cancellation, low memory, disk full, timeout
- [ ] Update error messages for user clarity

### Key Files
- `ImageProcessingService.swift` — Add limits + timeout
- `PhotoFileStore.swift` — Disk space + cleanup
- `SceneAndProcessingViews.swift:ProcessingView` — Cancellation support
- `AxleBackdropTests.swift` — New edge case tests

**Testing:** Simulate failures, verify graceful handling

---

## Summary: Phase 1 Progress

| Issue | Task | Status |
|-------|------|--------|
| **1** | Source photo preservation | ✅ Complete |
| **1** | Metadata tracking | ✅ Complete |
| **1** | Unit tests | ⏳ Final run (fix applied) |
| **2** | Vision validation framework | ⚪ Ready to start |
| **3** | Camera permissions | ⚪ Ready to start |
| **4** | Memory robustness | ⚪ Ready to start |

## Blockers
- **None.** All issues are independent and can be worked in parallel or sequence.

## Next Session Actions
1. **Verify Issue 1 test results** (should be done by now)
2. **Begin Issue 2 or 3** based on priority (suggest Issue 2 if corpus available, Issue 3 for parallel device work)
3. **Document findings in markdown** before going live
4. **After 4 issues fixed:** Proceed to Phase 2 (TestFlight beta validation)

## Notes for User
- All changes are **production-ready** after tests pass
- **No breaking changes** to existing functionality
- **Backward compatible** with older drafts
- Ready to commit once tests complete

---

*Plan file: `/Users/rdcorp/.claude/plans/projeyi-incele-eksik-g-rd-n-transient-barto.md`*
