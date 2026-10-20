"""Build an isolated MemorySampler Luau fixture."""
from pathlib import Path
import argparse

MARKER = "-- MEMORY_SAMPLER_MODULE_GOES_HERE"

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    directory = Path(__file__).resolve().parent
    fixture = (directory / "memory_sampler_fixture.luau").read_text(encoding="utf-8")
    module = (directory / "MemorySampler.lua").read_text(encoding="utf-8")
    if fixture.count(MARKER) != 1:
        raise RuntimeError("Memory fixture marker missing or duplicated")
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(fixture.replace(MARKER, "local MemorySampler = (function()\n" + module + "\nend)()"), encoding="utf-8")

if __name__ == "__main__":
    main()
