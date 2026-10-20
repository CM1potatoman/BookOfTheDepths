"""Build a standalone Luau fixture for RecoveryScope."""
from pathlib import Path
import argparse

MARKER = "-- RECOVERY_SCOPE_MODULE_GOES_HERE"

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    folder = Path(__file__).resolve().parent
    module = (folder / "RecoveryScope.lua").read_text(encoding="utf-8")
    fixture = (folder / "recovery_scope_fixture.luau").read_text(encoding="utf-8")
    if fixture.count(MARKER) != 1:
        raise RuntimeError("Fixture marker missing or duplicated")
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(fixture.replace(MARKER, "local RecoveryScope = (function()\n" + module + "\nend)()"), encoding="utf-8")

if __name__ == "__main__":
    main()
