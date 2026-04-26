# Road Beans Manual QA - v1

Run before each TestFlight build.

## Smoke
- [ ] Launch app cold; no crash; tab bar shows List, Map, +.
- [ ] Tap +; full-screen sheet presents the Place page.
- [ ] Add a custom place named "Test Stop" with kind Other.
- [ ] Page 2: leave date as-is; optionally add photos; add visit tag "qa".
- [ ] Page 3: add one drink named "Black coffee" with category Drip and rating 3.5.
- [ ] Save; toast "Added to Test Stop." appears.
- [ ] List shows the new place; tap it; Place Detail shows the visit.
- [ ] Open Visit Detail; drink, rating, tags, and any selected photos appear.
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
- [ ] Search by visit tag.
- [ ] Search by drink name in Recent Visits mode.

## Known V1 Limits
- [ ] Current-location sourcing is not wired yet; near-me uses the repository near-query path with a placeholder coordinate.
- [ ] iCloud data migration copy is not implemented; prompt flow is present for manual QA.
