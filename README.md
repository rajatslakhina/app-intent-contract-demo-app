# Intent Contract Gate — demo app

**Rename one App Intent, forget one alias row, and two of your users' saved Shortcuts stop working. This app shows which ones, and why the release gets blocked before it ships.**

A SwiftUI iOS app that runs eight proposed releases of a notes app's App Intents surface through [**IntentContracts**](https://github.com/rajatslakhina/app-intent-contract-kit). For each release it shows the gate's verdict, every classified change, and what happens to five Shortcuts and agent plans (captured on v0.9 and v1.0) when each one is replayed against the proposed release and compared with how it behaves on the published v1.0.0.

## Why this matters

In iOS 27, Siri, Apple Intelligence and in-app agents call your app through App Intents. The callers store your intent identifiers, parameter names and entity IDs, and they can't be recompiled. A rename that looks like a refactor in code review is a breaking API change for every one of them. This demo makes that visible: pick a release, and the screen tells you whether it is safe to ship and which recorded callers it would break or rescue.

## Screenshots

**None.** This app has **not** been run on a Simulator yet. On the 2026-10-22 run, computer-use access to Xcode and Simulator was granted, but Xcode's only window held an unrelated project that was already open, so the run stopped without clicking anything rather than disturb that work. No screenshots exist, and none are described here.

"It builds for the iOS Simulator" and "it ran on a Simulator" are different claims. See [Verification](#verification) for exactly which one is verified.

## What you would see

The app opens on the first proposal, **"Rename, alias forgotten"**. It shows a red **BLOCKED** banner (v1.0.0 → v1.1.0, declared minor, required major), and these findings:

- the 0.9-era alias `ShowNote → OpenNote` now dangles, and is also listed as a breaking change in its own right;
- the rename needs a major version but declares a minor;
- `OpenNote` was removed with no alias and no deprecation window;
- two recorded Shortcuts regress: "Open note 42" and the 0.9-era "Show note 7".

The chips across the top switch between the eight proposals. The verdicts below are the ones asserted by the library's `GateTests.testVerdictTable`:

| Proposal | Verdict |
|---|---|
| Rename, alias forgotten | Blocked |
| Rename with alias | Pass: both Shortcuts rescued, one of them through two alias hops |
| Namespaced IDs + shim | Pass: 3 stored-ID plans rescued; the shim's audit covers 4 legacy IDs with 0 collisions |
| Namespaced IDs, no shim | Blocked |
| Required folder as 1.1 | Blocked |
| Required folder + backfill | Pass |
| Remove ArchiveNote on schedule | Pass: the 0.9 Shortcut is shown as an accepted break |
| Summary becomes an entity | Blocked: the 3-step agent plan breaks at step 3, though no intent was removed |

## How it is put together

- `Demo/NotesIntents.swift` holds **real App Intents**: `OpenNote`, `CreateNote`, the `Note` entity (integer IDs, as v1.0.0 publishes them) and the `NoteColor` enum. `Note` publishes exactly the `title` and `tags` properties the contract declares. Static requirements are computed properties, written to be concurrency-safe in Swift 6 mode without holding global state.
- `Demo/NotesContract.swift` is the contract the app owns: the v1.0.0 surface, the recorded plans and the eight proposals. Identifiers for the real types are derived with `String(describing: OpenNote.self)` instead of retyped. The other four intents (`FindNotes`, `SummarizeNote`, `ArchiveNote`, `ShareText`) are modelled in the contract only. This file mirrors the library's test fixtures, so the verdicts here are the tested ones.
- `Demo/DemoApp.swift` builds `NotesContract.lab` (a `ContractLab`, which computes every report up front) and hands it to the library's `ContractLabView`. The view renders and computes nothing.
- The library comes in as a **remote Swift package** (`XCRemoteSwiftPackageReference` to `https://github.com/rajatslakhina/app-intent-contract-kit.git`). It is pinned to a version range, **"up to next major" from 1.0.0**, rather than to a branch, so it resolves to the newest 1.x release tag. No `Package.resolved` is committed, so a fresh clone gets the newest 1.x. It needs the library's `v1.0.0` tag to exist.

**Honest limits:** the surface is declared by hand next to the intents, not extracted from the compiled App Intents metadata. The app does not run iOS 27's `AppIntentsTesting` framework. Replay models invocations (identifiers, arguments, IDs, bindings); it does not drive a live app process.

## How to run it

1. `git clone https://github.com/rajatslakhina/app-intent-contract-demo-app.git`
2. Open `Demo.xcodeproj` in Xcode 16 or later. Xcode resolves `app-intent-contract-kit` from GitHub.
3. Select the **Demo** scheme and an iOS 17+ Simulator.
4. Build & Run (⌘R).

## Verification

- **Simulator run:** not done (see [Screenshots](#screenshots)).
- **CI:** not run yet at the time of writing. No Mac was available to this run, so none of the SwiftUI or App Intents code has been compiled by anyone yet: not `NotesIntents.swift`, not `DemoApp.swift`, and not the library's `ContractLabView`. The workflow defines one macOS 15 job. It resolves the package from GitHub (`xcodebuild -resolvePackageDependencies`), then builds the `Demo` scheme for `generic/platform=iOS Simulator` with signing disabled. When it passes, that will show the remote, version-pinned package resolves and the app (including the App Intents) compiles against it. It will not show that the app launches.
- **Contract logic:** `NotesContract.swift` was compiled against the library on Linux (Swift 6.0.3, warnings as errors) with stub types standing in for the App Intents. The eight verdicts printed matched the table above. The library's own suite asserts the same table.

## Related

- Library: [app-intent-contract-kit](https://github.com/rajatslakhina/app-intent-contract-kit)

## License

MIT
