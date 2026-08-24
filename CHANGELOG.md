# Changelog

All notable changes to NoICE are documented here. Newest entries first.

## 1.1 — 2026-08-24

### Changed
- Updated FAA holdover tables to the **Winter 2026-27** season (50 → 56 tables).
- Updated Transport Canada holdover tables to the **Winter 2026-27** season (53 → 56 tables).
- The source label in the header now reads "Winter 2026-27" for both authorities.

### Added
- New Type IV fluids: Newave Aerochemical FCY-EGIV PLUS, Shaanxi Cleanway Cleansurface IV,
  and Xinjiang Zhongtian Liyang Aviation Clearice-IV.
- New Type II fluid: ROMCHIM ADD-PROTECT Type II.
- New Type III entry: AllClear AeroClear MAX applied unheated, high speed ramp test.
- Generic Active Frost tables for Types II, III, and IV in the FAA source.
- Two precipitation conditions in the TCA source, matching FAA coverage:
  "Moderate snow mixed with rain" and "Snow mixed with freezing fog".
- Data-integrity test suite for the bundled tables (`DeicingDataTests`), covering holdover
  ordering, Celsius/Fahrenheit agreement, icon coverage, and table lookup resolution.

### Fixed
- Dynamic Island expanded view: added horizontal padding to the leading, trailing, and bottom
  regions so content no longer sits flush against the edges.

### Notes
- The generic Type IV table is numbered 20 this season (previously 19), following the addition
  of the new Type IV fluids.
- Project documentation added: README and LEARNING notes covering the seasonal update procedure.

## 1.0 — 2026-02

### Added
- Initial release: FAA and Transport Canada holdover tables for Winter 2025-26.
- Fluid type I/II/III/IV selection with concentration ratios.
- Holdover timer with animated progress bar and UTC start time.
- Live Activity and Dynamic Island support.
- Flaps factor (0.76) for extended flaps.
