# LEARNING.md — NoICE

## 2026-08-24 — Seasonal HOT table update (2025-26 → 2026-27)

**How the data swap works**
- The tables live in the HOTKit package, not the app: `HOTKit/Sources/HOTKit/Resources/DeicingTables{FAA,TCA}.xml`.
  Filenames are load-bearing — `DeicingHOTLoader` builds the resource name as `"DeicingTables\(source)"`,
  so incoming files must be renamed from `DeicingTables_FAA_2026-27.xml` to `DeicingTablesFAA.xml`.
- `Package.swift` uses `.process("Resources")`, so no manifest edit is needed for a same-name replacement.
- The season shown in the UI comes from `Info/PDF/@year` → `sourceLabel` = "Source: FAA Winter 2026-27".
  Only `publisher`, `season`, `year` are used; `file-name` is decoded but never read.
  **The app does not bundle or open the source PDFs** — shipping them adds bundle weight for nothing.

**Verification that actually catches problems**
- `swift build` / `swift test` CANNOT work on this package: `HOTLiveActivityManager` uses ActivityKit,
  which is unavailable on macOS, so the host-platform build fails before reaching any test.
  Use `xcodebuild test -scheme HOTKit -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`.
- Data-integrity tests live in `Tests/HOTKitTests/DeicingDataTests.swift`. They validate the shipped XML
  (HOT ordering, C/F agreement, icon coverage, table→condition resolution), not just parser mechanics.
- In the test target, do NOT pass `bundle: Bundle.module` — `Bundle.module` is only synthesised for targets
  that own resources, and HOTKitTests has none. Omit the argument so the loader resolves HOTKit's own bundle.

**Gotchas found while validating**
- Many `OutsideAirTemperature` elements carry only `FluidConcentration` children and no direct
  `WeatherCondition`. XMLCoder decodes the missing array as empty rather than throwing, so this is fine —
  a strict validator will flag hundreds of false positives here. The 2025-26 files have the same shape.
- Duplicate `(typeId, tableId)` keys exist and always have: Type 1 has two "TABLE 1:" tables
  (Aluminum + Composites). `TableItem.id` collides and `findTableItem` returns the first match.
  Pre-existing quirk, not a regression — but it means Type 1 Composites is unreachable by id lookup.
- Raw `WeatherCondition/@value` strings differ cosmetically between seasons ("SnowGrains" vs "Snow Grains",
  "Cold- Soaked" vs "Cold-Soaked", trailing commas). `cleanWeatherCondition` normalises all of these, so
  always diff the CLEANED names — the raw diff is misleading.
- `sfSymbolForPrecipitation` is keyword-based, so new condition names usually map without code changes.
  Assert against the `"cloud.fill"` fallback to detect vocabulary drift.

**What changed in 2026-27**
- FAA 50 → 56 tables, TCA 53 → 56. Both sources now expose the same 11 normalised conditions;
  TCA gained "Moderate snow mixed with rain" and "Snow mixed with freezing fog" (FAA already had both).
- Generic Type IV table renumbered 19 → 20 (not removed — three new Type IV fluids took 50/51/52).
- FAA gained Generic Active Frost tables for Types 2/3/4, aligning its structure with TCA.
