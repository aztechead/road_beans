# Road Beans Manual QA - v1

Run before each TestFlight build.

## Smoke
- [ ] Fresh install: launch app cold; onboarding appears and completes without crash.
- [ ] Relaunch after onboarding; tab bar shows List, Map, Backup, +.
- [ ] Tap +; full-screen sheet presents the Place page.
- [ ] Add a custom place named "Test Stop" with kind Other.
- [ ] Page 2: leave date as-is; optionally add photos; add visit tag "qa".
- [ ] Page 3: add one drink named "Black coffee" with category Drip and rating 3.5.
- [ ] Save; toast "Added to Test Stop." appears.
- [ ] List shows the new place; tap it; Place Detail shows the visit.
- [ ] Open Visit Detail; drink, rating, tags, and any selected photos appear.
- [ ] Place Detail toolbar Edit: change name/kind/address; List and Map reflect the update.
- [ ] Visit Detail toolbar Edit: change date, tags, drink name, drink rating, and photos; Recent Visits reflects the update.
- [ ] Visit Detail toolbar Trash -> Delete; list/detail/map refresh after deletion.

## Bean Slider
- [ ] Drag thumb across 0 to 5; haptic ticks occur at each 0.1 step and stronger feedback at whole numbers.
- [ ] Bean glyph count updates at 1, 2, 3, 4, and 5.
- [ ] VoiceOver focuses the slider as "Drink rating" with an adjustable value.
- [ ] Reduce Motion ON: no spring pulse animation.
- [ ] Reduce Transparency ON: thumb uses a solid background.
- [ ] Settings -> Accessibility -> Touch -> Vibration OFF: no haptic feedback.

## Dynamic Type
- [ ] Largest accessibility size remains usable.
- [ ] List rows, detail headers, drink rows, and toolbar actions do not clip important text.

## Dark Mode
- [ ] Toggle dark appearance; text remains visible.
- [ ] Glass cards, map sheets, tag chips, and rating controls remain readable.

## iCloud
- [ ] Sign out of iCloud, relaunch, and verify the relaunch/local-only path is understandable.
- [ ] Sign back into iCloud after running local-only; next launch shows the migration prompt.
- [ ] "Keep local only" dismisses the prompt and does not reappear on the next launch.

## Map
- [ ] Map tab loads without crashing.
- [ ] Existing places with coordinates appear as kind-tinted markers.
- [ ] Toggle "Stops near me"; if permission is denied, rationale and Open Settings appear.
- [ ] Tap a marker; glass sheet appears with "View visits".

## Search
- [ ] In List, search by place name.
- [ ] Search by place address.
- [ ] Search by visit tag.
- [ ] Search by drink name in Recent Visits mode.
- [ ] Combine kind, rating, tag, and date filters; results narrow correctly.
- [ ] Tap Clear; filters reset without losing selected List mode or search text.

## Backup Export
- [ ] Open Backup tab.
- [ ] Tap Prepare Export; no crash and Share Export File appears.
- [ ] Share/save the JSON file.
- [ ] Inspect JSON: `schemaVersion`, `places`, `visits`, `drinks`, `tags`, and `photoMetadata` keys are present.

## Known V1 Limits
- [ ] Near-me requires Location Services permission and an available device/simulator location fix.
- [ ] iCloud data migration copy is not implemented; prompt flow is present for manual QA.
- [ ] Backup export includes photo metadata only; raw photo binaries are not exported yet.
