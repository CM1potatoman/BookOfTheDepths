#!/usr/bin/env python3
"""Generate isolated Luau loader checks using mocked downloads and entry points.

The generated cases do not fetch Roblox content or execute any BOTD module.
"""

import argparse
import json
from pathlib import Path

CASES = {
    "success": "returned",
    "download-error": "download-error",
    "size-error": "size-error",
    "compile-error": "compile-error",
    "runtime-error": "runtime-error",
}

PRELUDE = r'''
local scenario = "@CASE@"
local status = {}
local warnings = {}
local getgenv = function() return status end
local warn = function(message)
    warnings[#warnings + 1] = tostring(message)
end

local sizes = { @SIZES@ }
local chunks = {}
for i, size in ipairs(sizes) do
    chunks[i] = string.rep(" ", size)
end
if scenario == "size-error" then
    chunks[2] = string.sub(chunks[2], 2)
end

local game = {}
function game:HttpGet(url)
    local num = url:match("CM1_Quiet_(%d%d)%.txt")
    assert(num, "unexpected URL " .. tostring(url))
    local index = tonumber(num)
    if scenario == "download-error" and index == 3 then
        error("synthetic transport failure")
    end
    return chunks[index]
end

function game:GetService(name)
    assert(name == "StarterGui")
    return { SetCore = function() end }
end

local loadstring = function(input)
    if scenario == "compile-error" then
        return nil, "synthetic compilation failed"
    end
    assert(type(input) == "string" and #input == @TOTAL@, "incorrect assembled data")
    return function()
        if scenario == "runtime-error" then
            error("synthetic execution failed")
        end
        return 917
    end
end

local function runLoader()
'''

POSTLUDE = r'''
end
local ok, result = pcall(runLoader)
assert(ok, "loader failed without reporting: " .. tostring(result))
assert(type(status.CM1QuietUIStatus) == "table", "missing status object")
assert(status.CM1QuietUIStatus.stage == "@EXPECTED@",
    "expected stage @EXPECTED@, got " .. tostring(status.CM1QuietUIStatus.stage))
if scenario == "success" then
    assert(result == 917, "loader did not forward the compiled return value")
    assert(#warnings == 0, "successful run generated a warning")
else
    assert(result == nil, "failed run returned a result")
    assert(#warnings >= 1, "failure did not generate a diagnostic warning")
end
print("PASS " .. scenario .. " => " .. status.CM1QuietUIStatus.stage)
'''


def generate(loader_path: Path, output: Path, manifest_path: Path) -> None:
    contents = loader_path.read_text(encoding="utf-8")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    sizes = [manifest["parts"][f"CM1_Quiet_{index:02d}.txt"] for index in range(1, 5)]
    assert sum(sizes) == manifest["total_bytes"], "Invalid manifest total"
    output.mkdir(parents=True, exist_ok=True)
    for name, expected in CASES.items():
        prelude = (PRELUDE.replace("@CASE@", name)
                   .replace("@SIZES@", ", ".join(str(size) for size in sizes))
                   .replace("@TOTAL@", str(manifest["total_bytes"])))
        postlude = POSTLUDE.replace("@EXPECTED@", expected)
        assembled = prelude + contents + "\n" + postlude
        (output / f"{name}.luau").write_text(assembled, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--loader", type=Path, default=Path("QuietUI/loader.lua"))
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--manifest", type=Path, default=Path("QuietUI/devtools/bundle_manifest.json"))
    args = parser.parse_args()
    generate(args.loader, args.out, args.manifest)


if __name__ == "__main__":
    main()
