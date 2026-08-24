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

## 2026-08-24 — Release 1.1: packaging and Xcode Cloud

**Xcode Cloud cannot build a local package reference**
- NoICE referenced HOTKit as `XCLocalSwiftPackageReference` with `relativePath = ../HOTKit`.
  Xcode Cloud clones only the primary repo, so a sibling path never exists on the builder.
  Converted to `XCRemoteSwiftPackageReference` on `https://github.com/aerofel/HOTKit.git`
  pinned `upToNextMajorVersion` from `1.2.0`.
- Consequence: **local HOTKit edits no longer reach the app.** Each HOTKit change now needs a
  commit, a new tag, and a `Package.resolved` update in NoICE.
- The way to actually prove this works is a clean clone into a directory with no sibling HOTKit,
  then build. Building in place passes even when the remote ref is broken, because SPM may reuse
  a cached checkout.

**aerofel/HOTKit is PRIVATE; aerofel/NoICE is PUBLIC**
- Xcode Cloud can still resolve it: HOTKit is granted to the Xcode Cloud GitHub App
  (it appears under `/v1/scmProviders/{id}/repositories`).
- But a public clone of NoICE cannot build without access to HOTKit. Worth revisiting if the
  repo is meant to be buildable by outsiders.

**Activating Xcode Cloud is GUI-only**
- The App Store Connect API refuses product creation:
  `403 The resource 'ciProducts' does not allow 'CREATE'. Allowed operations are: DELETE,
  GET_COLLECTION, GET_INSTANCE.`
- So the first-time onboarding must happen in Xcode (Product ▸ Xcode Cloud ▸ Create Workflow)
  or on the ASC website. Once a `ciProduct` exists, `POST /v1/ciBuildRuns` *can* start builds.
- `aerofel/NoICE` was not yet granted to the Xcode Cloud GitHub App — only Offto, sQRH, askM,
  starLOG, and HOTKit were. Granting it is part of the same onboarding step.

**App Store Connect facts for this app**
- Live: 1.0 (build 1). Repo HEAD had build 2, so 1.1 ships as **build 3** to stay monotonic.
- `deliver` only uploads metadata files that exist locally — absent files (e.g. `subtitle.txt`)
  leave the live values untouched. Useful for narrow metadata updates.
- precheck flagged two real issues: no `fastlane/metadata/copyright.txt`, and a marketing URL of
  `https://feel.aero/no-ice/` that 404s. The working page is `https://feel.aero/apps/no-ice`.
- A `fastlane/Deliverfile` with `app_identifier` is required for non-interactive runs.
