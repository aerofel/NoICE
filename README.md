# NoICE

Holdover time (HOT) calculator for flight crews and de-icing personnel, for iPhone.

NoICE turns the FAA and Transport Canada winter holdover tables into a fast lookup with a
running timer, a Live Activity, and Dynamic Island support — so the holdover window stays
visible from the ramp to the runway without unlocking the phone.

## Features

- **FAA and TCA tables** — switch sources at any time; the active season is shown in the header.
- **Guided lookup** — pick fluid type (I / II / III / IV), concentration, OAT, and precipitation
  to get the applicable holdover range.
- **Live timer** — animated progress bar with green / caution / expired zones, elapsed and
  remaining time, and UTC (Zulu) start time.
- **Live Activity + Dynamic Island** — the countdown continues on the lock screen.
- **Flaps factor** — applies the 0.76 multiplier for extended flaps.
- **Celsius and Fahrenheit** throughout.

## Data sources

Holdover data ships as XML inside the [HOTKit](https://github.com/aerofel/HOTKit) package:

| Source | File | Season |
|---|---|---|
| FAA | `DeicingTablesFAA.xml` | Winter 2026-27 |
| Transport Canada | `DeicingTablesTCA.xml` | Winter 2026-27 |

Both are regenerated from the published regulatory PDFs each season. See
[LEARNING.md](LEARNING.md) for the update and verification procedure.

## Project layout

```
NoICE/          iOS app target — header, settings, source switching
NoICEWidget/    Widget extension — Live Activity and Dynamic Island views
../HOTKit/      Swift package — data models, XML loader, and the main HOT views
fastlane/       App Store metadata and delivery config
```

Most of the UI lives in HOTKit (`HOTView`, `TimeBarView`, `FluidRatioViews`) so the app and the
widget can share it.

## Building

Requires Xcode with an iOS 16.2+ deployment target.

```sh
xcodebuild build -project NoICE.xcodeproj -scheme NoICE \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

HOTKit cannot be built or tested on macOS — it depends on ActivityKit, which is iOS-only.
Run its tests against a simulator:

```sh
cd ../HOTKit
xcodebuild test -scheme HOTKit -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Safety notice

NoICE is an aid, not an authority. Holdover times are estimates and the pilot in command remains
responsible for determining that the aircraft is clean before takeoff. Always refer to the current
official FAA or Transport Canada holdover tables and your operator's procedures.
