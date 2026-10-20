"""Build a native Linoria FloatingWindow contract fixture."""
from pathlib import Path
import argparse

REGISTRATION = b'__bundle_register("Menu/Objects/FloatingWindow", function(require, _LOADED, __bundle_register, __bundle_modules)\n'
MARKER = b"-- FLOATING_WINDOW_MODULE_GOES_HERE"

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    source = b"".join((args.root / "QuietUI/parts" / f"CM1_Quiet_{i:02d}.txt").read_bytes() for i in range(1, 5))
    begin = source.find(REGISTRATION)
    if begin < 0:
        raise RuntimeError("FloatingWindow registration missing")
    bodyStart = begin + len(REGISTRATION)
    end = source.find(b'__bundle_register("', bodyStart)
    body = source[bodyStart:end].rstrip()
    if not body.endswith(b"return FloatingWindow\nend)"):
        raise RuntimeError("Unexpected FloatingWindow module boundary")
    body = body[:-len(b"\nend)")]
    fixture = (Path(__file__).parent / "floating_window_fixture.luau").read_bytes()
    if fixture.count(MARKER) != 1:
        raise RuntimeError("Fixture marker missing")
    output = fixture.replace(MARKER, b"local FloatingWindow = (function(require, _LOADED, __bundle_register, __bundle_modules)\n" + body + b"\nend)(mockRequire, nil, nil, nil)")
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_bytes(output)

if __name__ == "__main__":
    main()
