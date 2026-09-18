# Changelog

All notable changes to NoICE are documented here. Newest entries first.

## Unreleased

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
