# TestFlight Beta v1.0.2 - Release Notes

**Build:** 1.0.2 (Build 2)  
**Date:** 2026-11-16  
**Tester Group:** Internal → External  

---

## 🎯 What's New in This Build

### Fixed: Source Photo Integrity ✅
- Original photos now preserved byte-for-byte without re-encoding
- Improved backup and recovery capabilities
- Better metadata tracking for advanced editing features

### Improved: Camera & Permission Handling ✅
- Graceful fallback to Photo Library if camera unavailable
- Better permission status detection on app resume
- Automatic recovery from interruptions

### Improved: Processing Robustness ✅
- Added memory limits and timeout protection
- Better disk space validation
- More reliable error handling during processing

---

## 🧪 What We Need From You

Help us test:

1. **Photo Capture**
   - Take photos on your iPhone (not just simulator)
   - Test with vehicles in different lighting
   - Check that both exterior composites look sharp

2. **Segmentation Quality**
   - Does the vehicle extraction work well?
   - Any artifacts or missing parts?
   - How does it handle different vehicle types?

3. **Stability**
   - Process 5+ listings start-to-finish
   - Try on both iPhone and iPad if possible
   - Test exporting to Photos library

4. **Camera**
   - Grant/deny camera permission
   - Switch apps during capture
   - Retake photos

---

## 📋 Known Limitations

- ⚠️ Segmentation validated only on test images (not real vehicles yet)
- ⚠️ Camera tested only on simulators (real device testing needed)
- ⚠️ Processing robustness tested in lab conditions

---

## 🐛 How to Report Issues

- **Performance**: Note iPhone model, iOS version, photo resolution
- **Quality**: Attach before/after photos if possible
- **Crashes**: Include full error message from app

---

## 📞 Support

- **Questions**: Contact support@axlebackdrop.app
- **Privacy**: Photos never leave your device unless explicitly exported
- **Feedback**: Your input shapes the next release

---

## 👥 Testers Needed

- iPhone 16 / 16 Pro (latest)
- iPhone 15 / 15 Pro (previous gen)
- iPhone 14 / 14 Pro (baseline)
- iPad (if available)

---

## ✅ Before Next Release

Based on TestFlight feedback, v1.0.3 will focus on:
- Real vehicle photo corpus validation
- Refinement of segmentation parameters
- Performance optimization for battery/memory

Thank you for testing! 🙏
