# Road Beans Install and Release Checklist

## Debug Local-Device Mode

Use this mode for personal-team iPhone installs and day-to-day simulator development.

- [ ] Select the `Road Beans` scheme.
- [ ] Select `Debug` configuration.
- [ ] Use the default target settings: `Road Beans/Road_Beans.Local.entitlements` and `ROAD_BEANS_LOCAL_DEVICE`.
- [ ] Build for a simulator or attached iPhone.
- [ ] Confirm the build log entitlements do not include `aps-environment` or `com.apple.developer.icloud-services`.
- [ ] Confirm persistence starts in local-only mode even when the device is signed into iCloud.
- [ ] Confirm AppIntents metadata extraction writes metadata and does not warn about missing AppIntents dependency.

Verify:

```bash
xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" -destination 'generic/platform=iOS' build
```

Simulator build and test smoke:

```bash
xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" -destination 'generic/platform=iOS Simulator' build
xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:"Road BeansTests/SmokeTests"
```

Physical iPhone run:

- [ ] Connect the iPhone and trust the Mac.
- [ ] In Xcode, select the attached iPhone as the run destination.
- [ ] Keep `Debug` selected for personal-team installs.
- [ ] If signing fails, verify `DEVELOPMENT_TEAM` is set to a team available on the Mac and the bundle identifier is unique for that team.
- [ ] Run from Xcode once; after install, launch directly from the phone and verify onboarding, Add Visit, List, Map, and Backup tabs.

## Release CloudKit-Capable Mode

Use this mode only with an Apple Developer Program team that can provision iCloud/CloudKit and Push capabilities for the bundle identifier.

- [ ] Select `Release` configuration.
- [ ] Confirm `Road Beans/Road_Beans.entitlements` is active.
- [ ] Confirm the paid team owns or can provision `brainmeld.Road-Beans`.
- [ ] Configure the CloudKit container `iCloud.brainmeld.Road-Beans` before distribution.
- [ ] Build/archive with automatic signing or a matching provisioning profile.
- [ ] Run the manual QA checklist before TestFlight upload.
- [ ] Export a JSON backup from the Backup tab before testing any future CloudKit migration path.

Archive:

```bash
xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" -configuration Release -destination 'generic/platform=iOS' archive
```

## Current Limitation

- [ ] CloudKit migration copy is still intentionally not implemented; local-device mode is the safest path for physical-device testing until that work is complete.
- [ ] Backup export intentionally excludes raw photo binaries in the current implementation; JSON includes photo metadata only.
