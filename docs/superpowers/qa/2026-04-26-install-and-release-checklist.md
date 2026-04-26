# Road Beans Install and Release Checklist

## Debug Local-Device Mode

Use this mode for personal-team iPhone installs and day-to-day simulator development.

- [ ] Select the `Road Beans` scheme.
- [ ] Select `Debug` configuration.
- [ ] Use the default target settings: `Road Beans/Road_Beans.Local.entitlements` and `ROAD_BEANS_LOCAL_DEVICE`.
- [ ] Build for a simulator or attached iPhone.
- [ ] Confirm the build log entitlements do not include `aps-environment` or `com.apple.developer.icloud-services`.
- [ ] Confirm persistence starts in local-only mode even when the device is signed into iCloud.

Verify:

```bash
xcodebuild -project "Road Beans.xcodeproj" -scheme "Road Beans" -destination 'generic/platform=iOS' build
```

## Release CloudKit-Capable Mode

Use this mode only with an Apple Developer Program team that can provision iCloud/CloudKit and Push capabilities for the bundle identifier.

- [ ] Select `Release` configuration.
- [ ] Confirm `Road Beans/Road_Beans.entitlements` is active.
- [ ] Confirm the paid team owns or can provision `brainmeld.Road-Beans`.
- [ ] Configure the CloudKit container `iCloud.brainmeld.Road-Beans` before distribution.
- [ ] Build/archive with automatic signing or a matching provisioning profile.

## Current Limitation

- [ ] CloudKit migration copy is still intentionally not implemented; local-device mode is the safest path for physical-device testing until that work is complete.
