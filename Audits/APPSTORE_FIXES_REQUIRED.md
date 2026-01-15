# Vecka App - Critical Fixes Required for App Store Submission

This document provides step-by-step instructions for fixing the critical issues identified in the audit.

## CRITICAL FIX #1: Deployment Target (iOS 26.0 → 18.0)

### Issue
Current deployment target is iOS 26.0, which does not exist. Maximum released iOS is 18.2.

### Fix Steps

1. Open Xcode project:
   ```bash
   open /Users/nilsjohansson/Documents/AppDevelopment/Swift/Vecka/Vecka.xcodeproj
   ```

2. In Xcode, select project "Vecka" in the navigator

3. Select target "Vecka" (main app)

4. Go to "Build Settings" tab

5. Search for "IPHONEOS_DEPLOYMENT_TARGET"

6. Change value from `26.0` to `18.0`

7. Repeat for target "VeckaWidgetExtension"

8. Verify with command line:
   ```bash
   xcodebuild -project /Users/nilsjohansson/Documents/AppDevelopment/Swift/Vecka/Vecka.xcodeproj \
     -target Vecka -showBuildSettings | grep IPHONEOS_DEPLOYMENT_TARGET
   ```
   Should output: `IPHONEOS_DEPLOYMENT_TARGET = 18.0`

**Severity:** CRITICAL - App cannot install without this fix

---

## CRITICAL FIX #2: App Name (Onsen Planner → Onsen Planner)

### Issue
Info.plist displays "Onsen Planner" but project should be "Onsen Planner" per CLAUDE.md

### Fix Steps

1. Edit Info.plist:
   ```bash
   /usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" \
     /Users/nilsjohansson/Documents/AppDevelopment/Swift/Vecka/Vecka/Info.plist
   ```
   Current output: `Onsen Planner`

2. Update CFBundleDisplayName:
   ```bash
   /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName Onsen Planner" \
     /Users/nilsjohansson/Documents/AppDevelopment/Swift/Vecka/Vecka/Info.plist
   ```

3. Update CFBundleName:
   ```bash
   /usr/libexec/PlistBuddy -c "Set :CFBundleName Onsen Planner" \
     /Users/nilsjohansson/Documents/AppDevelopment/Swift/Vecka/Vecka/Info.plist
   ```

4. Verify:
   ```bash
   /usr/libexec/PlistBuddy -c "Print" \
     /Users/nilsjohansson/Documents/AppDevelopment/Swift/Vecka/Vecka/Info.plist | grep -A 1 "CFBundleName\|CFBundleDisplayName"
   ```

**Severity:** CRITICAL - Wrong app name on App Store

---

## CRITICAL FIX #3: Privacy Manifest (PrivacyInfo.xcprivacy)

### Issue
App Store requires privacy manifest for all apps since January 2024. Currently missing.

### Fix Steps

1. Create privacy manifest file:
   ```bash
   touch /Users/nilsjohansson/Documents/AppDevelopment/Swift/Vecka/Vecka/PrivacyInfo.xcprivacy
   ```

2. Add the following content to PrivacyInfo.xcprivacy:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSPrivacyTracking</key>
	<false/>
	<key>NSPrivacyTrackingDomains</key>
	<array/>
	<key>NSPrivacyAccessedAPITypes</key>
	<array>
		<dict>
			<key>NSPrivacyAccessedAPIType</key>
			<string>NSPrivacyAccessedAPICategoryUserDefaults</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array>
				<string>CA92.1</string>
			</array>
		</dict>
		<dict>
			<key>NSPrivacyAccessedAPIType</key>
			<string>NSPrivacyAccessedAPICategoryCalendar</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array>
				<string>1C8F.1</string>
			</array>
		</dict>
		<dict>
			<key>NSPrivacyAccessedAPIType</key>
			<string>NSPrivacyAccessedAPICategoryContacts</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array>
				<string>E7BE.1</string>
			</array>
		</dict>
		<dict>
			<key>NSPrivacyAccessedAPIType</key>
			<string>NSPrivacyAccessedAPICategoryPhotos</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array>
				<string>0A2A.1</string>
			</array>
		</dict>
		<dict>
			<key>NSPrivacyAccessedAPIType</key>
			<string>NSPrivacyAccessedAPICategoryCamera</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array>
				<string>E235.1</string>
			</array>
		</dict>
		<dict>
			<key>NSPrivacyAccessedAPIType</key>
			<string>NSPrivacyAccessedAPICategoryLocation</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array>
				<string>3E17.1</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
```

3. Add file to target membership:
   - Open Xcode
   - Select PrivacyInfo.xcprivacy
   - Go to File Inspector (right panel)
   - Check box for "Vecka" target

4. Verify file exists and is valid:
   ```bash
   plutil -lint /Users/nilsjohansson/Documents/AppDevelopment/Swift/Vecka/Vecka/PrivacyInfo.xcprivacy
   ```
   Should output: `PrivacyInfo.xcprivacy: OK`

**Severity:** CRITICAL - App Store submission will be rejected without this

---

## CRITICAL FIX #4: CloudKit Entitlements

### Issue
VeckaApp.swift uses CloudKit (`cloudKitDatabase: .automatic`) but entitlements not configured.

### Fix Steps

1. Edit Vecka/Vecka.entitlements:
   ```bash
   open /Users/nilsjohansson/Documents/AppDevelopment/Swift/Vecka/Vecka/Vecka.entitlements
   ```

2. Add CloudKit container identifier inside the `<dict>` (before closing tag):

```xml
	<key>com.apple.developer.icloud-container-identifiers</key>
	<array>
		<string>iCloud.Johansson.Vecka</string>
	</array>
```

3. Final entitlements file should look like:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.weatherkit</key>
	<true/>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.Johansson.Vecka</string>
	</array>
	<key>com.apple.developer.icloud-container-identifiers</key>
	<array>
		<string>iCloud.Johansson.Vecka</string>
	</array>
</dict>
</plist>
```

4. Verify syntax:
   ```bash
   plutil -lint /Users/nilsjohansson/Documents/AppDevelopment/Swift/Vecka/Vecka/Vecka.entitlements
   ```
   Should output: `Vecka.entitlements: OK`

5. Also update widget entitlements to include CloudKit (for sync):
   ```bash
   nano /Users/nilsjohansson/Documents/AppDevelopment/Swift/Vecka/VeckaWidget/VeckaWidget.entitlements
   ```
   Add same CloudKit container identifier array

**Severity:** MEDIUM - CloudKit sync may fail without this

---

## VERIFICATION CHECKLIST

After applying all fixes, verify:

```bash
# 1. Check deployment target
xcodebuild -project /Users/nilsjohansson/Documents/AppDevelopment/Swift/Vecka/Vecka.xcodeproj \
  -target Vecka -showBuildSettings | grep "IPHONEOS_DEPLOYMENT_TARGET"
# Expected: IPHONEOS_DEPLOYMENT_TARGET = 18.0

# 2. Check app name
/usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" \
  /Users/nilsjohansson/Documents/AppDevelopment/Swift/Vecka/Vecka/Info.plist
# Expected: Onsen Planner

# 3. Check privacy manifest exists and is valid
plutil -lint /Users/nilsjohansson/Documents/AppDevelopment/Swift/Vecka/Vecka/PrivacyInfo.xcprivacy
# Expected: PrivacyInfo.xcprivacy: OK

# 4. Check entitlements are valid
plutil -lint /Users/nilsjohansson/Documents/AppDevelopment/Swift/Vecka/Vecka/Vecka.entitlements
# Expected: Vecka.entitlements: OK

# 5. Test build
xcodebuild build -project /Users/nilsjohansson/Documents/AppDevelopment/Swift/Vecka/Vecka.xcodeproj \
  -scheme Vecka -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
# Expected: BUILD SUCCEEDED
```

---

## BUILD AND SUBMIT

Once all fixes are applied:

1. **Clean build:**
   ```bash
   xcodebuild clean -project /Users/nilsjohansson/Documents/AppDevelopment/Swift/Vecka/Vecka.xcodeproj \
     -scheme Vecka
   ```

2. **Test build on simulator:**
   ```bash
   xcodebuild build -project /Users/nilsjohansson/Documents/AppDevelopment/Swift/Vecka/Vecka.xcodeproj \
     -scheme Vecka -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
     CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
   ```

3. **Archive for TestFlight/App Store:**
   - Open Xcode
   - Select scheme "Vecka"
   - Product → Archive
   - Select archive and click "Distribute App"
   - Choose "TestFlight & App Store"

4. **Submit to App Store:**
   - Use Xcode's distribution workflow
   - Or use Transporter app
   - Fill in App Store metadata (screenshots, description, etc.)

---

**Last Updated:** 2026-01-06  
**Status:** PENDING - All 4 critical fixes must be applied
