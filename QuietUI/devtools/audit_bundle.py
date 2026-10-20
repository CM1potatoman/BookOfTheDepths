#!/usr/bin/env python3
"""Read-only static integrity and lifecycle audit for split Luau source files."""

from __future__ import annotations

import argparse
from bisect import bisect_right
from collections import Counter
from hashlib import sha1, sha256
import json
from pathlib import Path
import re
import sys

REGISTRATION = re.compile(rb'__bundle_register\("([^"\r\n]+)",\s*function')
LEGACY_REQUIRE = re.compile(rb'require\(["\']GUI/Library["\']\)')


def check_bundle(root: Path, manifest: dict) -> dict:
    parts_dir = root / "QuietUI" / "parts"
    expected = manifest["parts"]
    expected_hashes = manifest.get("git_blob_sha1", {})
    issues: list[dict] = []
    chunks: list[bytes] = []
    actual_sizes: dict[str, int] = {}

    for filename, expected_size in expected.items():
        file = parts_dir / filename
        if not file.is_file():
            issues.append({"severity": "error", "code": "missing_part", "file": filename})
            continue
        body = file.read_bytes()
        actual_sizes[filename] = len(body)
        chunks.append(body)
        if filename in expected_hashes:
            prefix = b"blob " + str(len(body)).encode("ascii") + b"\x00"
            actual_hash = sha1(prefix + body).hexdigest()
            if actual_hash != expected_hashes[filename]:
                issues.append({"severity": "error", "code": "part_hash_mismatch",
                               "file": filename, "expected": expected_hashes[filename],
                               "actual": actual_hash})
        if len(body) != expected_size:
            issues.append({"severity": "error", "code": "part_size_mismatch", "file": filename,
                           "expected": expected_size, "actual": len(body)})

    complete = len(chunks) == len(expected)
    data = b"".join(chunks)
    if complete and len(data) != manifest["total_bytes"]:
        issues.append({"severity": "error", "code": "bundle_size_mismatch",
                       "expected": manifest["total_bytes"], "actual": len(data)})

    registrations = list(REGISTRATION.finditer(data))
    names = [match.group(1).decode("utf-8", "replace") for match in registrations]
    duplicates = sorted(name for name, count in Counter(names).items() if count > 1)
    for name in duplicates:
        issues.append({"severity": "error", "code": "duplicate_module", "module": name})

    if complete and len(names) != manifest["registered_modules"]:
        issues.append({"severity": "error", "code": "module_count_mismatch",
                       "expected": manifest["registered_modules"], "actual": len(names)})

    if complete and not data.rstrip().endswith(b'return __bundle_require("__root")'):
        issues.append({"severity": "error", "code": "missing_entry_point"})

    offsets = [item.start() for item in registrations]
    legacy_users = []
    for match in LEGACY_REQUIRE.finditer(data):
        index = bisect_right(offsets, match.start()) - 1
        legacy_users.append(names[index] if index >= 0 else "<outside module>")
    legacy_users = sorted(set(legacy_users))
    if legacy_users:
        issues.append({"severity": "warning", "code": "legacy_ui_imports",
                       "module_count": len(legacy_users), "modules": legacy_users})

    if b'get_bloxstrap_rpc()' in data:
        issues.append({"severity": "warning", "code": "unguarded_optional_rpc_candidate"})
    if re.search(rb'while\s+true\s+do\s+task\.wait\(reportInterval\)', data):
        issues.append({"severity": "warning", "code": "profiler_unbounded_loop_candidate"})
    if b'violin-suzutsuki/LinoriaLib/main/' in data:
        issues.append({"severity": "warning", "code": "linoria_dependency_unpinned"})

    return {
        "status": "pass" if not any(i["severity"] == "error" for i in issues) else "fail",
        "source_root": str(root.resolve()),
        "complete": complete,
        "size_bytes": len(data),
        "sha256": sha256(data).hexdigest(),
        "module_count": len(names),
        "unique_module_count": len(set(names)),
        "part_sizes": actual_sizes,
        "issues": issues,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--manifest", type=Path,
                        default=Path(__file__).with_name("bundle_manifest.json"))
    parser.add_argument("--json", action="store_true", help="emit machine-readable audit report")
    parser.add_argument("--strict", action="store_true", help="also fail on existing warnings")
    args = parser.parse_args(argv)

    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    result = check_bundle(args.root, manifest)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print(f"Bundle audit: {result['status'].upper()}")
        print(f"Bytes: {result['size_bytes']} | Registered: {result['module_count']} "
              f"| Unique: {result['unique_module_count']}")
        print(f"SHA-256: {result['sha256']}")
        for issue in result["issues"]:
            print(f"[{issue['severity'].upper()}] {issue['code']}")

    if result["status"] == "fail":
        return 1
    if args.strict and result["issues"]:
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
