#!/usr/bin/env python3
"""Read-only inventory of the existing legacy UI dependency contract."""
from __future__ import annotations
import argparse
from collections import Counter
import json
from pathlib import Path
import re
import sys

BASELINE = frozenset(["Luma","Features/Automation/AutoSaramed","Utility/Logger","Features/Automation/Objects/AutomationFeatures","Features/Automation/AutoNotes","Features/Automation/AutoMooneyrie","Features/Automation/AutoDuke","Features/Automation/AutoAuthority","Features/Automation/AutoTitus","Features/Automation/AutoFerryman","Features/Automation/AutoVoI","Features/Automation/AutoTo1","Features/Combat/Objects/Defender","Features/Combat/Objects/AnimatorDefender","Menu/AutoBuilderWindow","Features/Automation/AutoLayer2","Features/Automation/EchoFarm","Features/Combat/AnimationInspector","Features/Exploits/AnimationFlooder","Features/Game/AnimationVisualizer","Features/Visuals/ProximityList","Features/Custom/CustomAPI","Features/Custom/CustomWidgets","Menu/CustomTab","Menu/Objects/FloatingWindow","Menu/Objects/CodeEditor","Menu/CombatTab","Features/Combat/SilentAim","Menu/TimingBuilderTab","GUI/Linoria"])
MIGRATED = frozenset({"Menu/Objects/FloatingWindow"})
MODULE = re.compile(r'__bundle_register\("([^"]+)",\s*function')
LEGACY = re.compile(r'require\(["\x27]GUI/Library["\x27]\)')
REQUIRE_VAR = re.compile(r'\blocal\s+([A-Za-z_]\w*)\s*=\s*require\(["\x27]GUI/Library["\x27]\)')


def inspect(source: str) -> dict:
    registrations = list(MODULE.finditer(source))
    dependents = []
    for index, match in enumerate(registrations):
        end = registrations[index + 1].start() if index + 1 < len(registrations) else len(source)
        body = source[match.start():end]
        if not LEGACY.search(body):
            continue
        variables = sorted(set(REQUIRE_VAR.findall(body)))
        methods: set[str] = set()
        properties: set[str] = set()
        for name in variables:
            prefix = re.escape(name)
            methods.update(re.findall(r'\b' + prefix + r'\s*:\s*(\w+)\s*\(', body))
            properties.update(re.findall(r'\b' + prefix + r'\s*\.\s*(\w+)', body))
        dependents.append({
            "module": match.group(1),
            "variables": variables,
            "methods": sorted(methods),
            "properties": sorted(properties),
        })
    names = {item["module"] for item in dependents}
    method_counts: Counter[str] = Counter()
    property_counts: Counter[str] = Counter()
    for item in dependents:
        method_counts.update(item["methods"])
        property_counts.update(item["properties"])
    return {
        "registered_modules": len(registrations),
        "legacy_dependents": len(dependents),
        "unexpected_new_dependencies": sorted(names - BASELINE),
        "baseline_dependencies_removed": sorted(BASELINE - names),
        "regressed_migrations": sorted(names & MIGRATED),
        "method_users": dict(sorted(method_counts.items(), key=lambda item: (-item[1], item[0]))),
        "property_users": dict(sorted(property_counts.items(), key=lambda item: (-item[1], item[0]))),
        "modules": sorted(dependents, key=lambda item: item["module"]),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--strict", action="store_true",
                        help="Reject newly introduced legacy UI consumers")
    args = parser.parse_args()
    source = "".join(
        (args.root / "QuietUI" / "parts" / f"CM1_Quiet_{index:02d}.txt").read_text(encoding="utf-8")
        for index in range(1, 5)
    )
    report = inspect(source)
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print(f'Legacy GUI: {report["legacy_dependents"]} dependent modules')
        print(f'Unexpected dependencies: {report["unexpected_new_dependencies"]}')
        print(f'Baseline consumers removed: {report["baseline_dependencies_removed"]}')
        print(f'Regressed migrations: {report["regressed_migrations"]}')
    return 1 if args.strict and (report["unexpected_new_dependencies"] or report["regressed_migrations"]) else 0


if __name__ == "__main__":
    sys.exit(main())
