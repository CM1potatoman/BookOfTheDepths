# QuietUI recovery tooling

This directory contains source auditing, standalone tests, and lifecycle helpers. The development branch also embeds a matching `Utility/RecoveryScope` module in the four-part QuietUI bundle. Diagnostic tools do not execute the gameplay bundle.

## Static source audit

Run from the repository root:

    python QuietUI/devtools/audit_bundle.py
    python QuietUI/devtools/audit_bundle.py --json
    python -m unittest discover -s QuietUI/devtools -p "test_*.py" -v

Python 3.10+ is sufficient. No additional packages or Roblox executor are needed.

The auditor reads the four source parts as bytes, validates lengths against bundle_manifest.json, checks their Git blob SHA-1 hashes, counts module registrations, rejects duplicates, and verifies the final bundle entry point. It also reports *candidate* lifecycle and legacy UI issues. Static warnings do not prove runtime faults.

The manifest describes the source at the original QuietUI upload. After an intentional bundle edit, its byte sizes and Git blob hashes must be regenerated from reviewed, committed files. Do not merely change a hash to make an unexpected alteration pass.

## Standalone Luau modules

- RecoveryScope.lua owns temporary threads, RBXScriptConnections, Instances, and cleanup callbacks. Closing a scope stops its repeating tasks and releases tracked resources. It uses no game-specific hooks.
- MemorySampler.lua reads Stats.GetTotalMemoryUsageMb and, when supported, gcinfo. Its watcher needs an injected scope implementing every(interval, callback).

The independent smoke test, `linoria_smoke.lua`, opens only a Linoria window with basic controls. It does not load BOTD features. It requires an environment providing `game:HttpGet` and `loadstring`; standard client Roblox Studio scripts do not necessarily provide these APIs. A passing compile check alone does not prove its UI rendered.

The updated `QuietUI/loader.lua` on the review branch reports its initial stage through warnings and `getgenv().CM1QuietUIStatus` when available. The status `returned` means only that the top-level function returned without raising a synchronous error. It does not confirm that asynchronous game initialization, UI components, or background tasks succeeded.

The standalone MemorySampler remains independent, while RecoveryScope is integrated into the development bundle. GitHub Actions verifies Luau compilation and mocked runtime contracts; Studio execution, live-game behavior, and in-client reload behavior remain unverified.

Memory figures are **whole-client** measurements, not per-feature allocations. A client-memory increase alone does not establish a leak. Compare multiple repeated runs against a baseline and include sample times and workload.

## Remaining integration work

- Migrate the modules that still depend on GUI/Library to an independently tested Linoria compatibility layer before removing the legacy UI implementation.
- Ensure the existing menu's unload paths always finish, including when optional integrations are unavailable.
- Give any new UI pollers and profiling loops cancellable lifecycle ownership.
- Pin external UI dependencies to reviewed revisions.
- Keep diagnostics explicit. Do not confuse silent console output with correct behavior.

No modification here establishes runtime execution or detection safety. The original root loader and its 14 source parts remain unchanged. The development branch's four QuietUI source parts contain intentional reviewed changes recorded in the current manifest.

## Development branch loader

The `quietui-linoria-stability-20261019` loader downloads the corresponding branch's source parts. The root `loader.lua` and the `main/QuietUI/loader.lua` production loader remain unchanged. The split-source length/hash manifest is updated alongside any intentional part modification. The isolated loader harness reads sizes from that manifest. Do not merge the draft PR until the development download path has been deliberately reviewed for production deployment.

## Integrated resume lifecycle

The development bundle registers `Utility/RecoveryScope` and uses it to manage the ten conditional resume tasks in `Luma.init()`. `Luma.detach()` cancels owned tasks before the other cleanup calls. Optional errors are recorded in a bounded `getgenv().CM1QuietUIErrors` list only when `getgenv().CM1QuietUIDebug == true`. Gameplay feature modules are unchanged. Runtime execution has not yet been verified.

## Legacy GUI migration inventory

Run `python QuietUI/devtools/legacy_ui_inventory.py --json` for a per-module list of legacy UI dependencies and the methods/properties each consumer calls. `--strict` rejects new legacy consumers relative to the existing 30-module baseline. Existing consumers can be migrated and removed from that list without breaking the check. This tool does not remove the legacy implementation or establish visual compatibility.

## Opt-in diagnostics

When `getgenv().CM1QuietUIDebug == true`, `Utility/Logger.warn` and `.trace` append records to `getgenv().CM1QuietUIDiagnostics`, keeping only the last 100 entries. This does not print, transmit, or persist diagnostics. With the flag off, calls return without buffering. Resume-worker errors are separately buffered in `CM1QuietUIErrors` with a 50-entry limit. These buffers do not validate runtime behavior; use them with reproducible test steps.

## RecoveryScope lifecycle regression

The development branch carries the same RecoveryScope implementation in `devtools/RecoveryScope.lua` and the bundled `Utility/RecoveryScope` module. Completed/failed worker registrations now retire immediately instead of remaining referenced until unload. CI executes `recovery_scope_fixture.luau` in mocked Luau, checking completion, cancellation, error isolation and 50 consecutive scope cycles. This is not an in-game reload verification.

## Native Linoria floating window

`Menu/Objects/FloatingWindow` now imports `GUI/Linoria` instead of `GUI/Library`, so windows are parented to Linoria's ScreenGui and use its native Create, registration, and dragging implementations. The isolated `floating_window_fixture.luau` verifies construction, presentation, callbacks and legacy-free import behavior with mocked Roblox GUI objects. Remaining legacy consumers still require migration; do not remove `GUI/Library` yet.

## Controlled memory measurement

`MemorySampler.new(label)` starts a labeled baseline and `sampler:reset(label)` starts another independent run. Samples retain both whole-client and available Lua-heap baselines, deltas, peaks and counts. A mocked Luau harness checks distinct runs, invalid samples, and scoped periodic collection. These readings include allocations outside BOTD; they must not be interpreted as proof of leakage without a controlled Roblox experiment.

The legacy dependency inventory's `--strict` mode also rejects reintroducing imports in `MIGRATED`, starting with `Menu/Objects/FloatingWindow`. Add entries only after a consumer is migrated and independently tested.
