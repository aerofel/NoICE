# No-ICE Nearby Share — BLE protocol v1

Status: implemented on iOS / iPadOS (NoICE 1.2, HOTKit 1.4.0). Android: see
`NoICE-Android/docs/handoffs/2026-09-26-ble-nearby-share.md`.

Nearby Share lets one device push its current state (timer, weather, temperature, fluid, flaps,
FAA/TCA source) to every nearby device that has No-ICE **open in the foreground**. The link is
plain Bluetooth LE GATT. There is no pairing, no bonding, no account and no pre-connection.

Everything below is normative. The iOS reference implementation lives in:

| Concern | File |
|---|---|
| Constants, INFO record, compatibility | `HOTKit/Sources/HOTKit/Share/NearbyShareInfo.swift` |
| Framing / reassembly | `HOTKit/Sources/HOTKit/Share/NearbyShareFraming.swift` |
| Payload, capture, resolution | `HOTKit/Sources/HOTKit/Share/HOTShareSnapshot.swift` |
| Applying a share | `HOTState.applyShared` and `HOTView.applyExternal` (HOTKit) |
| CoreBluetooth transport | `NoICE/NoICE/Share/NearbyShareService.swift` |
| Golden test vectors | `HOTKit/Tests/HOTKitTests/Fixtures/` |

## 1. Roles and lifetime

- While the app is in the foreground, every device is **both** a GATT server (peripheral) and a
  GATT client (central).
- Start when the app becomes active. Stop when it goes to the background. Do not stop on
  transient states (iOS `.inactive`, Android `onPause` caused by a dialog or split screen).
- No background modes are used.

## 2. Identifiers

| Item | UUID |
|---|---|
| Service (primary, advertised) | `627CA4E3-B51F-4EFD-96EB-AD3359484171` |
| INFO characteristic | `5F1226BD-388E-474E-9782-D490D874D8A1` |
| INBOX characteristic | `CA63C2B9-4EC9-49F0-97A0-F8115F35DD7F` |

The GATT database is static. Characteristics may be **added** in later versions but are never
removed or changed, so no Service Changed indication is needed.

## 3. Advertising and scanning

- Advertise the 128-bit service UUID only (flags 3 bytes + UUID 18 bytes = 21 of 31 bytes).
  No local name, no TX power, no service or manufacturer data. The advertisement is connectable.
  (iOS cannot advertise anything else. Keeping both platforms identical keeps it simple.)
- Scan with a filter on the service UUID and receive duplicate reports, so presence can be
  tracked.
- A peer is **present** while advertisements keep arriving. It **expires 10 s after the last
  one**.

## 4. INFO characteristic

Properties: Read. Permission: readable, **no encryption** (encryption would trigger pairing).
The value is UTF-8 JSON and may be longer than one ATT packet, so servers must support long
reads (offset). Clients read it once per newly seen BLE address.

```json
{"v":1,"id":"3F2504E0-4F89-11D3-9A0C-0305E82C3301","name":"Pixel 9","platform":"android","app":"2.1","db":{"FAA":"2026-27","TCA":"2026-27"}}
```

| Key | Type | Meaning |
|---|---|---|
| `v` | int | Protocol major version (1). |
| `id` | string | Random UUID generated **once per app launch**. Used to deduplicate a peer across BLE address rotation (both platforms use rotating private addresses). It is not a stable device id. |
| `name` | string? | Device name for display. |
| `platform` | string? | `ios`, `ipados` or `android`. |
| `app` | string? | App version, informational. |
| `db` | object | Table season per source, from the `year` attribute of the `<PDF>` header of `DeicingTablesFAA.xml` / `DeicingTablesTCA.xml`. |

**Compatible** means the same `v`, and `db.FAA` and `db.TCA` both present and equal on both
sides. Only compatible peers enable the share button and receive shares.

Discovery procedure (client):
1. An advertisement arrives from an unknown address: wait a random 0–400 ms (so two devices do
   not connect to each other at the same instant), connect, discover the service, read INFO,
   disconnect.
2. Run **one discovery connection at a time**. Use a timeout of 8 s. On failure, wait 5 s
   before trying that address again.
3. If `id` equals your own, ignore the address. If `id` is already known, attach the new
   address to the existing peer.
4. Unknown JSON keys are ignored.

## 5. INBOX characteristic and framing

Properties: Write (with response). Permission: writeable, no encryption.

A payload is sent as a sequence of writes. **Each write is one frame and fits in one ATT
packet**, so no prepared (long) writes are ever needed:

```
START  0x01 | total payload length, UInt32 big-endian | first payload bytes
CONT   0x02 | next payload bytes
```

- Frame size ≤ ATT_MTU − 3.
  - iOS: `maximumWriteValueLength(for: .withoutResponse)`. Do **not** use the `.withResponse`
    value, which is always 512 and implies long writes.
  - Android: request MTU 517 and use `mtu − 3`.
  - The minimum is 20.
- Frames are written **with response**, one at a time. The next frame is sent only after the
  previous response. This gives ordering and flow control.
- The receiver keeps one buffer per client connection.
  - START always resets that buffer.
  - The buffer is dropped on disconnect, or after 15 s without a frame.
- Maximum payload: 16 384 bytes.
- The response to the **final** frame is sent only after the payload has been decoded and
  checked. A successful final response therefore means "delivered". The sender's UI counts
  deliveries ("Sent to 2 devices").

ATT results on INBOX:

| Code | Name | When |
|---|---|---|
| `0x00` | success | Frame accepted; on the final frame: payload valid and queued for the user. |
| `0x07` | invalid offset | Write with a non-zero offset (prepared write). |
| `0x0D` | invalid attribute value length | START with length 0 or > 16 384, truncated START header, more bytes than announced. |
| `0x0E` | unlikely error | CONT without START, empty write, unknown frame type. |
| `0x80` | decode failed (application) | Complete payload is not valid JSON / not a v1 snapshot. |
| `0x81` | database mismatch (application) | Payload `db` differs from the receiver's seasons. |

Golden vector (`Fixtures/framing-v1.txt`): payload = UTF-8 `noice.share test payload
0123456789` (35 bytes), frame size 20:

```
01000000236e6f6963652e736861726520746573
0274207061796c6f616420303132333435363738
0239
```

Sending procedure (client): for each compatible peer **in turn**:
1. Connect.
2. Discover the service.
3. Rebuild the snapshot now, so the timer offset is fresh.
4. Write the frames.
5. Disconnect.

Use a 10 s timeout per peer.

## 6. Payload v1 (`HOTShareSnapshot`)

UTF-8 JSON. Unknown keys are ignored. Optional keys may be absent or `null`.

```json
{
  "type": "noice.share",
  "v": 1,
  "sentAt": "2026-09-26T14:50:12Z",
  "sender": "iPhone",
  "db": { "FAA": "2026-27", "TCA": "2026-27" },
  "source": "TCA",
  "weather": { "condition": "Light freezing rain", "precipitations": "all", "intensity": "light" },
  "temperature": { "c": -6, "value": -6, "unit": "C" },
  "fluid": {
    "typeId": 4,
    "table": "4-34",
    "tableTitle": "Type IV Holdover Times for Clariant Safewing MP IV LAUNCH PLUS",
    "entryTempC": { "lower": -8, "upper": -3 },
    "ratio": "75/25"
  },
  "flapsExtended": true,
  "timer": { "state": "running", "startedSecAgo": 312.5, "holdMarksSec": [60, 125.25] }
}
```

| Key | Req. | Meaning |
|---|---|---|
| `type` | yes | Always `noice.share`. Anything else is rejected (`0x80`). |
| `v` | yes | 1. Any other value is rejected (`0x80`). |
| `sentAt` | no | ISO 8601, informational only (never used for timing). |
| `sender` | no | Display name. |
| `db` | yes | Sender's seasons; must equal the receiver's (`0x81`). |
| `source` | yes | `FAA` or `TCA`, the sender's tables. The receiver switches to it on accept. |
| `weather.condition` | no | Condition title **as listed by the loader** (the cleaned title: first word capitalised, e.g. `Light freezing rain`). |
| `weather.precipitations`, `weather.intensity` | no | Filter chip keys (`all`, `rain`, `snow`, … / `all`, `very light`, `light`, `moderate`, …). Default `all`. |
| `temperature.c` | yes | Outside air temperature in °C. |
| `temperature.value`, `.unit` | yes | The value as shown by the sender, and its unit (`C`/`F`). |
| `fluid` | no | Absent when no fluid is selected, or when the selected fluid's band no longer covers the temperature. |
| `fluid.typeId` | yes | 1…4. |
| `fluid.table` | yes | `"<type>-<table number>"`, e.g. `4-34`. |
| `fluid.tableTitle` | no | Full table title. When present, it must match the receiver's table. |
| `fluid.entryTempC` | yes | °C bounds of the table row in use. |
| `fluid.ratio` | yes | Fluid/water mix, e.g. `75/25` (Type I: `100/0`). |
| `flapsExtended` | yes | HOT × 0.76 when true. |
| `timer.state` | yes | `idle`, `running` or `paused`. |
| `timer.startedSecAgo` | no | Seconds from timer start to the moment of sending (default 0). |
| `timer.holdMarksSec` | no | Hold (pause) marks as seconds after start, ascending (default `[]`). |

### Timer semantics

- Times are **relative on purpose**, so clocks may differ between devices. The receiver records
  `receivedAt` when the final frame arrives (not when the user taps Accept), and sets
  `start = receivedAt − startedSecAgo`.
- A hold mark does not shift the start. Paused time still counts, as in the app. While paused,
  the displayed elapsed time is the last hold mark.
- `idle` resets the receiver's timer.

### Resolution on the receiver

This is what `HOTShareResolver` does:
1. **Switch source.** Switch to `source` first.
2. **Temperature.**
   - If `unit` matches the receiver's unit, use `value`; otherwise convert `c`.
   - Round to 1°, then clamp to the tables' global range.
3. **Fluid.**
   - Look up the table (`findTableItem(condition, type, table)`), check `tableTitle`, find the
     row with exactly `entryTempC`, then find `ratio`.
   - If all are found, clamp the temperature into that row's band (in the receiver's unit).
4. **Condition.**
   - The condition must be listed by the loader for the resolved temperature and chips.
   - If it isn't, drop the condition **and** the fluid.
5. **Missing fluid.** A fluid that can't be found is reported to the user ("could not be
   matched"). Weather, flaps and timer are still applied.

## 7. User experience rules

- **Share button.** It sits under the settings button.
  - Grayed out while no compatible peer is present.
  - Glowing, with a count badge, when at least one is present.
  - Tapping it sends to every compatible peer.
  - Tapping it while it is grayed out explains why (no one nearby, Bluetooth off, not allowed).
- **Receiving.**
  - The receiver always asks: a confirmation sheet that summarises the share, with **Decline**
    and **Accept**. Nothing changes until Accept.
  - Decline is silent (no reply is sent in v1).
  - Only one offer is pending at a time; a newer offer replaces it.
  - Offers from the same client within 3 s are ignored (acknowledged but not shown).
- **Timer warning.** If the receiver's timer is active, the sheet warns that it will be
  replaced.

## 8. Versioning

- New optional keys (INFO or payload) and new characteristics are **minor** changes. Keep
  `v = 1`; older apps ignore them.
- Anything that changes the meaning of an existing key, the framing or the UUIDs requires
  `v = 2`. Peers with different `v` are shown as incompatible and never exchange payloads.

## 9. Platform notes

**iOS**
- `NSBluetoothAlwaysUsageDescription` is required; the prompt appears at first launch.
- Peripheral side:
  - Add the service once per process and never remove it; only start and stop advertising.
  - INFO is a static value, so CoreBluetooth answers reads, long reads included.
  - Answer each `didReceiveWrite` batch **once**, with `respond(to: requests[0], …)`.

**Android** (details in the handoff)
- Permissions:
  - API 31+: `BLUETOOTH_SCAN` (with `neverForLocation`), `BLUETOOTH_ADVERTISE`,
    `BLUETOOTH_CONNECT`.
  - API ≤ 30: `BLUETOOTH`, `BLUETOOTH_ADMIN`, `ACCESS_FINE_LOCATION`, and Location Services
    must be on.
- `connectGatt(..., TRANSPORT_LE)`. Run one GATT operation at a time. Call `requestMtu(517)`
  before discovery. On status 133: `close()`, wait 500 ms, retry once. Always `close()`.
- Do not restart scans to refresh presence: Android allows at most 5 `startScan` calls per 30 s.
- If `bluetoothLeAdvertiser` is null, the device can send but cannot be discovered. Say so in
  the UI.
