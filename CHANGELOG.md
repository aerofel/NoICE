# Changelog

All notable changes to NoICE are documented here. Newest entries first.

## Unreleased — 2026-10-03 09:55 UTC

### Changed
- The "Device integrity compromised" screen now has the app's header banner (logo, gradient title,
  source · season · unit) instead of a small logo row. The banner moved to `HeaderBanner.swift`, shared
  with the main screen. On the blocked screen it has no gear or share button, its status line can't be
  tapped, and it keeps the same height.

## Unreleased — 2026-10-03 09:45 UTC

### Changed
- Jailbreak detection no longer uses IOSSecuritySuite, because its EULA doesn't allow paid apps on the
  free plans. `NoICE/JailbreakChecks.swift` now runs the same families of checks offline, in about
  200 lines of our own code:
  - jailbreak files, including rootless `/var/jb` and RootHide's `/var/.jbroot-*`, seen through
    lstat, access and FileManager
  - symlinked system folders
  - a read-write system volume and writes outside the sandbox
  - fork() (the child exits at once)
  - injected tweak libraries, matched by exact name or install folder
  - bypass-tweak classes
  - jailbreak URL schemes, with `palera1n` added
- Only iPhone and iPad are checked: the app runs normally on a Mac (Designed for iPad, Catalyst) and on
  Vision Pro.

## Unreleased — 2026-10-03 07:13 UTC

### Added
- Jailbreak detection (for the civil-aviation approval file): on a jailbroken iPhone or iPad the app
  shows a full-screen "Device integrity compromised" notice instead of the hold-over screen, and
  Nearby Share never starts. Detection uses IOSSecuritySuite 2.3.0 (files, sandbox writes, fork,
  symlinks, injected libraries, jailbreak URL schemes declared in `NoICE/Info.plist`). It is skipped
  in the simulator and when the iPad app runs on a Mac. In DEBUG builds, `-SimulateJailbreak YES`
  shows the notice.

## 2.0 — 2026-09-27 17:39 UTC

### Added
- Nearby Share: a new button under the settings gear sends the running timer, weather condition,
  temperature, fluid, mix, flaps and FAA/TCA source to every nearby iPhone, iPad or Android device
  with No-ICE open and the same table seasons. It uses Bluetooth LE with no pairing. The button is
  grayed out while nobody is nearby and glows with a device count when someone is. Receivers
  confirm in a sheet that summarises the share and warns before replacing a running timer.
  Protocol: `docs/NEARBY_SHARE_PROTOCOL.md`.

### Fixed
- Live Activity lock screen: the context strip no longer truncates every pill ("-6…", "IV ·…").
  Condition and temperature are on the first row; fluid, flaps and PAUSED are on the second.
- A fluid dropped because the temperature left its band no longer comes back on relaunch.

### Changed
- Redesigned the fluid picker. Fluid types are pills with the real dye colours and a count of
  products approved for the current condition; types with nothing approved are dimmed.
- Products are listed by brand and name (the table number is a small badge) with a search field
  and a "Recent" group holding the last three fluids used.
- Concentrations (100/0, 75/25, 50/50) are fixed chips showing assured and limit times. A mix the
  table does not list at the current temperature stays visible but dimmed.
- The selected fluid is a hero card that mirrors the Live Activity, with the mix chips still
  available so switching mixes is one tap. "Change fluid" reopens the list on the same product.
- Type I shows two surface cards (Aluminum, Composite) instead of two long document titles.
- Type II and III colours are now legible in light and dark mode.
- Redesigned the weather zone to match: minus and plus steppers around the temperature slider with
  a large tinted readout, precipitation and intensity filter chips with labels, condition rows with
  a weather symbol and a temperature-band pill, and a hero row for the selected condition with
  "Change condition". Filters that leave nothing show an empty state with "Clear filters".
- Refreshed the timer card to match: small uppercase labels, Zulu times as pills, a context strip
  showing condition, temperature, fluid and flaps factor while a fluid is selected, hold-over
  durations shown before start instead of clock times, and a hint that follows the timer state.
- Nudging the temperature no longer drops the selected fluid while its table band still applies.
- Aircraft flaps/slats are now two cards (UP / Extended) matching the other zones, and the
  section appears as soon as a condition is selected instead of only after a fluid.
- Header: the tagline is replaced by a live status line (source, season, unit) that opens the
  settings menu, the gear sits in a round bubble, the logo has a soft icy glow, and the glass
  card gets a frost highlight and a softer shadow.
- Live Activity restyled to match: the lock screen header is the same pill strip as the timer card
  (condition, temperature, fluid in its dye colour, flaps ×0.76 only when extended, paused pill),
  uppercase ELAPSED / ASSURED / LIMIT labels with rounded digits, and Dynamic Island views that use
  the fluid colour and the same pills.
- Concentration chips, timer digits and flaps cards now scale their text instead of wrapping at large Dynamic Type sizes.

## 1.1 — 2026-08-24

### Changed
- Updated FAA holdover tables to the **Winter 2026-27** season (50 → 56 tables).
- Updated Transport Canada holdover tables to the **Winter 2026-27** season (53 → 56 tables).
- The source label in the header now reads "Winter 2026-27" for both authorities.

### Added
- New Type IV fluids: LNT Solutions P450, MAX TECH LLC MTL 4-EG, and MAX TECH LLC MTL 4-PG.
- New Type II fluid: LNT Solutions P250.
- Generic Active Frost tables for Types II, III, and IV in the FAA source.
- Two precipitation conditions in the TCA source, matching FAA coverage:
  "Moderate snow mixed with rain" and "Snow mixed with freezing fog".
- Data-integrity test suite for the bundled tables (`DeicingDataTests`), covering holdover
  ordering, Celsius/Fahrenheit agreement, icon coverage, and table lookup resolution.

### Removed
- AVIAFLUID AVIAFlight EG (Type IV) — withdrawn by the publishers. Its PG counterpart is
  unaffected and remains in the tables.

### Fixed
- Dynamic Island expanded view: added horizontal padding to the leading, trailing, and bottom
  regions so content no longer sits flush against the edges.
- Precipitation-condition labels in both sources: upstream typos normalised
  ("SnowGrains" to "Snow Grains", "Cold- Soaked" to "Cold-Soaked", stray trailing commas).

### Notes
- The three AllClear AeroClear MAX Type III tables were renamed by the publishers, from
  "applied unheated on low/middle/high speed aircraft" to "applied unheated - low/middle/high
  speed ramp test". Same fluid, same numbers; only the label changed.
- The generic Type IV table is numbered 20 this season (previously 19), following the addition
  of the new Generic Active Frost entry.
- Project documentation added: README and LEARNING notes covering the seasonal update procedure.

## 1.0 — 2026-02

### Added
- Initial release: FAA and Transport Canada holdover tables for Winter 2025-26.
- Fluid type I/II/III/IV selection with concentration ratios.
- Holdover timer with animated progress bar and UTC start time.
- Live Activity and Dynamic Island support.
- Flaps factor (0.76) for extended flaps.
