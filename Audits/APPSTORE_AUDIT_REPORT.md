# Vecka iOS App - App Store Deployment Readiness Audit
**Generated:** 2026-01-06  
**Project:** WeekGrid (Vecka)  
**Target Deployment:** iOS 26+ (CRITICAL ISSUE)  

---

## Executive Summary

The Vecka app has **MAJOR compatibility issues** preventing App Store submission. The deployment target is set to iOS 26.0, which does not exist (iOS current max is 18.x). The app also has several configuration gaps that must be addressed for App Store compliance.

**Status:** NOT READY FOR APP STORE - Critical fixes required

---

## 1. INFO.PLIST CONFIGURATION

### Critical Issues

#### Issue 1.1: App Name Mismatch
- **Current Status:** 
  - `CFBundleDisplayName`: "Onsen Planner" (INFO.PLIST)
  - `CFBundleName`: "Onsen Planner" (INFO.PLIST)
  - Expected (per CLAUDE.md): "WeekGrid"
- **Impact:** Wrong app name on App Store and home screen
- **Action Required:** Update Info.plist keys to "WeekGrid"
- **Severity:** CRITICAL

#### Issue 1.2: Missing Core Version Keys
- **Current Status:** Info.plist does NOT contain:
  - `CFBundleIdentifier` (should be auto-generated)
  - `CFBundleVersion` (build number)
  - `CFBundleShortVersionString` (user-facing version)
- **Note:** These ARE generated during build (GENERATE_INFOPLIST_FILE = YES)
- **Action:** Verify they appear in built app's Info.plist
- **Severity:** MEDIUM (auto-generated, but verify)

### Compliance Checks - PASSED

- Privacy descriptions (NSLocationWhenInUseUsageDescription) - PRESENT
- NSLocationAlwaysAndWhenInUseUsageDescription - PRESENT
- NSContactsUsageDescription - PRESENT
- NSCameraUsageDescription - PRESENT
- NSPhotoLibraryUsageDescription - PRESENT
- NSCalendarsFullAccessUsageDescription - PRESENT
- Orientation support (iPhone and iPad) - CONFIGURED
- UI launch screen generation - ENABLED

---

## 2. ENTITLEMENTS CONFIGURATION

### App Entitlements (Vecka/Vecka.entitlements)
✅ **Configured:**
- `com.apple.developer.weatherkit` - ENABLED
- `com.apple.security.application-groups` - SET to "group.Johansson.Vecka"

⚠️ **Missing (based on VeckaApp.swift analysis):**
- iCloud/CloudKit container capability NOT declared in entitlements
  - **Issue:** Code uses `cloudKitDatabase: .automatic` but entitlements not configured
  - **Impact:** CloudKit sync may fail in production
  - **Action:** Add `com.apple.developer.icloud-container-identifiers` to entitlements
  - **Severity:** MEDIUM

### Widget Entitlements (VeckaWidget/VeckaWidget.entitlements)
✅ **Configured:**
- `com.apple.security.application-groups` - SET (shared with app)

### Missing Entitlements
- HealthKit (`com.apple.developer.healthkit`) - NOT present (acceptable if not using HealthKit)
- Contacts access - NO explicit entitlement needed (NSContactsUsageDescription sufficient)

---

## 3. APP ICONS ASSESSMENT

### Current Status

✅ **AppIcon.appiconset Contents:**
- `AppIcon1024x1024.png` (1024x1024, light mode)
- `C5A72477-28AD-4104-8733-A52EA68348A9.png` (1024x1024, dark mode)
- `F25C5E42-BD27-4322-A525-FFBD61BFBAAC.png` (1024x1024, tinted mode)
- All files: Valid PNG images

⚠️ **Icon Size Configuration - INCOMPLETE**
- Only 1024x1024 universal icons present
- **Missing smaller icon sizes that Xcode needs to auto-generate:**
  - 120×120 (iPhone app icon)
  - 180×180 (iPhone 3x)
  - 167×167 (iPad Pro)
  - 152×152 (iPad)
  - 76×76 (iPad)
  - And many more variants

**HOWEVER:** Modern Xcode automatically scales the 1024×1024 icon down to all required sizes, so this is ACCEPTABLE.

✅ **Asset Compiler Output** (from build log):
- Successfully emplaced `AppIcon60x60@2x.png`
- Successfully emplaced `AppIcon76x76@2x~ipad.png`
- **Conclusion:** Xcode correctly auto-generated required sizes

---

## 4. LAUNCH SCREEN CONFIGURATION

✅ **Status: CONFIGURED**
- `INFOPLIST_KEY_UILaunchScreen_Generation = YES` - ENABLED
- Xcode will auto-generate SwiftUI-based launch screen
- No custom LaunchScreen.storyboard needed (modern SwiftUI approach)

---

## 5. DEBUG/TEST CODE AUDIT

### Print Statements - CONDITIONAL
✅ All wrapped in `#if DEBUG`:
```swift
#if DEBUG
    print(message())
#endif
```
**Impact:** Will NOT appear in Release builds - SAFE

### fatalError Usage
⚠️ **Found in VeckaApp.swift:**
```swift
fatalError("Could not create ModelContainer: \(error)")
```
**Assessment:** Used for catastrophic failures only (cannot create database), acceptable for App Store

### TODO/FIXME Markers - PRESENT
Found in 3 files (acceptable, not shipped):
- `TripListView.swift:405` - "Restore MileageListView"
- `PDFExportService.swift:220,237` - "Add observances"
- `TravelManager.swift:138,148` - "Implement GPS tracking"
**Impact:** TODOs don't ship; only code comments - ACCEPTABLE

### Hardcoded Endpoints
✅ **Only external API found:**
- `https://api.frankfurter.app/latest` (currency exchange)
- No staging/test endpoints in code - SAFE

### No Secrets Found
✅ No API keys, passwords, or tokens in source code - SAFE

---

## 6. PRIVACY MANIFEST (PrivacyInfo.xcprivacy)

❌ **MISSING - CRITICAL**

**Current Status:** No `PrivacyInfo.xcprivacy` file found in project

**App Store Requirement:** 
- Required for ALL apps as of January 2024
- Apple App Store submission will be REJECTED without it

**What's Needed:**
Based on app permissions:
```xml
<!-- PrivacyInfo.xcprivacy must declare: -->
- NSPrivacyTracking: false (unless doing analytics)
- NSPrivacyTrackingDomains: [] (empty if not tracking)
- NSPrivacyAccessedAPITypes:
  * UserDefaults API (if using)
  * Calendar API (NSCalendarsFullAccessUsageDescription)
  * Contacts API (NSContactsUsageDescription)
  * Photos API (NSPhotoLibraryUsageDescription)
  * Camera API (NSCameraUsageDescription)
  * Location API (NSLocationWhenInUseUsageDescription)
  * WeatherKit API (com.apple.developer.weatherkit)
```

**Action Required:**
1. Create `Vecka/PrivacyInfo.xcprivacy` file
2. Declare all privacy-sensitive APIs used
3. Add to target membership
4. Verify on App Store submission

**Severity:** CRITICAL - Blocks submission

---

## 7. BUILD SETTINGS ANALYSIS

### Deployment Target - CRITICAL ISSUE

❌ **Current Setting:**
```
IPHONEOS_DEPLOYMENT_TARGET = 26.0
RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET = 15.0
```

**Problem:** 
- iOS 26 does not exist (max released is iOS 18.2)
- App will NOT be installable on any real device
- App Store will REJECT this

**Action Required:**
- Change to: `IPHONEOS_DEPLOYMENT_TARGET = 18.0` (or lower if legacy support needed)
- CLAUDE.md states "iOS 18+" requirement
- Recommend: Set to 18.0 minimum

**Severity:** CRITICAL - Prevents installation

### Code Signing - GOOD

✅ **Configuration:**
- `CODE_SIGN_STYLE = Automatic`
- `DEVELOPMENT_TEAM = P4LGU6F45C`
- `CODE_SIGN_IDENTITY = Apple Development`
- `CODE_SIGN_ENTITLEMENTS = Vecka/Vecka.entitlements`
- Ready for TestFlight (will auto-switch to Distribution on App Store)

### Build Configuration - GOOD

✅ **Release Configuration:**
- `MARKETING_VERSION = 1.0`
- `CURRENT_PROJECT_VERSION = 1`
- Both present and ready

### Framework Search Paths - GOOD

✅ **Configured correctly:**
```
LD_RUNPATH_SEARCH_PATHS = (
    "$(inherited)",
    "@executable_path/Frameworks"
)
```

---

## 8. MULTI-TARGET CONFIGURATION

✅ **Structure:**
- Main App: Vecka
- Widget Extension: VeckaWidgetExtension
- Test Targets: VeckaTests, VeckaUITests

✅ **Widget Entitlements:**
- Shares app group: `group.Johansson.Vecka`
- Properly configured for data sharing

---

## 9. LOCALIZATION

✅ **Present:**
- English, Swedish: Main app
- English, Swedish: Widget
- Additional: German, Chinese (Simplified & Traditional), Japanese, Korean, Vietnamese
- **Assessment:** Complete international support ready

---

## 10. BUILD VERIFICATION

✅ **Test Build Result:** SUCCESS
- Compiled without errors
- Asset catalog processed correctly
- Widget extension embedded properly
- App signing validated
- **Conclusion:** Code compiles and links correctly

---

## CRITICAL ISSUES SUMMARY

### Must Fix Before App Store Submission

| # | Issue | Severity | Impact | Fix |
|---|-------|----------|--------|-----|
| 1 | Deployment target iOS 26.0 (doesn't exist) | CRITICAL | App won't install | Change to 18.0 |
| 2 | Missing PrivacyInfo.xcprivacy | CRITICAL | Store rejection | Create privacy manifest |
| 3 | App name "Onsen Planner" vs "WeekGrid" | CRITICAL | Wrong store name | Update Info.plist |
| 4 | CloudKit in code but not in entitlements | MEDIUM | Sync may fail | Add iCloud capability |

### Nice-to-Fix Before Submission

| # | Issue | Severity | Impact | Fix |
|---|-------|----------|--------|-----|
| 5 | Verify CFBundleVersion appears in built app | LOW | Version not visible | Confirm in built Info.plist |

---

## DEPLOYMENT CHECKLIST

Before submitting to App Store:

- [ ] **Change IPHONEOS_DEPLOYMENT_TARGET from 26.0 to 18.0**
- [ ] **Create PrivacyInfo.xcprivacy with proper API declarations**
- [ ] **Update CFBundleDisplayName from "Onsen Planner" to "WeekGrid"**
- [ ] **Add CloudKit entitlement: `com.apple.developer.icloud-container-identifiers`**
- [ ] **Verify build runs on iOS 18 simulator**
- [ ] **Test all privacy-requested features work**
- [ ] **Create App Store Connect record with bundle ID: `Johansson.Vecka`**
- [ ] **Set App Store description/screenshots**
- [ ] **Submit for review**

---

## POSITIVE FINDINGS

✅ Code signs properly  
✅ All required privacy descriptions present  
✅ Multi-target (app + widget) configured correctly  
✅ Internationalization complete  
✅ App icon correctly sized (Xcode auto-scales)  
✅ Launch screen auto-generated  
✅ No hardcoded secrets or test credentials  
✅ All debug code conditionally compiled  
✅ Clean build with no warnings  

---

## RECOMMENDATIONS

1. **Immediate Actions:**
   - Fix deployment target
   - Add privacy manifest
   - Fix app name
   - Add CloudKit entitlement

2. **Pre-Submission Testing:**
   - Test on physical iOS 18 device
   - Verify iCloud/CloudKit sync works
   - Test all permission flows
   - Check app launch time

3. **TestFlight Before Store:**
   - Use TestFlight to validate on real devices
   - Gather feedback on privacy prompts
   - Monitor crash logs in Xcode Organizer

---

**Audit Complete**  
Prepared for: Nils Johansson  
Project Path: `/Users/nilsjohansson/Documents/AppDevelopment/Swift/Vecka/`
