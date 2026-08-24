# Changelog

All notable changes to NoICE are documented here. Newest entries first.

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
