#!/usr/bin/env python3
"""Extract just the Linoria adapter for isolated Luau runtime compatibility checks."""

from __future__ import annotations

import argparse
from pathlib import Path
import re

BEGIN = re.compile(
    rb'__bundle_register\("GUI/Linoria",\s*function\(require,\s*_LOADED,\s*'
    rb'__bundle_register,\s*__bundle_modules\)\s*'
)
END = b'__bundle_register("GUI/LinoriaAddons", function('
MARKER = b'-- ADAPTER_MODULE_GOES_HERE'


def assemble(root: Path, output: Path) -> int:
    files = [
        root / "QuietUI" / "parts" / f"CM1_Quiet_{i:02d}.txt"
        for i in range(1, 5)
    ]
    data = b"".join(path.read_bytes() for path in files)
    begin = BEGIN.search(data)
    if begin is None:
        raise RuntimeError("GUI/Linoria bundle registration is missing")
    end = data.find(END, begin.end())
    if end < 0:
        raise RuntimeError("Following GUI/LinoriaAddons module is missing")

    fragment = data[begin.end():end]
    fragment = re.sub(rb'\s*end\)\s*$', b"", fragment)
    if not fragment.rstrip().endswith(b"return Library"):
        raise RuntimeError("GUI/Linoria module has an unexpected ending")

    fixture = (Path(__file__).parent / "ui_adapter_fixture.luau").read_bytes()
    if fixture.count(MARKER) != 1:
        raise RuntimeError("Fixture must contain exactly one insertion marker")

    registration = (
        b"local Adapter = (function(require, _LOADED, __bundle_register, __bundle_modules)\n"
        + fragment
        + b"\nend)(requireMock, nil, nil, nil)\n"
    )
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(fixture.replace(MARKER, registration))
    return len(fragment)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    size = assemble(args.root, args.out)
    print(f"Generated isolated Linoria adapter compatibility test from {size:,} source bytes")


if __name__ == "__main__":
    main()
