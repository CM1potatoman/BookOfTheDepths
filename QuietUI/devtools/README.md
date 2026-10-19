# QuietUI recovery tooling

This directory contains standalone, read-only diagnostics and lifecycle helpers. They do **not** modify or execute the bundled gameplay code, and they are not currently wired into the four-part loader.

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

These Luau files are intentionally independent and are **not integrated** into the current bundle. Luau compilation, Studio runtime, live-game behavior, and reload tests have not been verified.

Memory figures are **whole-client** measurements, not per-feature allocations. A client-memory increase alone does not establish a leak. Compare multiple repeated runs against a baseline and include sample times and workload.

## Remaining integration work

- Migrate the modules that still depend on GUI/Library to an independently tested Linoria compatibility layer before removing the legacy UI implementation.
- Ensure the existing menu's unload paths always finish, including when optional integrations are unavailable.
- Give any new UI pollers and profiling loops cancellable lifecycle ownership.
- Pin external UI dependencies to reviewed revisions.
- Keep diagnostics explicit. Do not confuse silent console output with correct behavior.

No modification here establishes runtime execution or detection safety. The original root loader and the QuietUI gameplay parts remain unchanged on this branch.
