# CM1 Deepwoken Quiet UI build

This is the Quiet UI variant transferred from the unrelated ArchivistCM1 repository on 2026-10-19.

- Main repository's existing `loader.lua` and `parts/` remain unchanged.
- `loader.lua` downloads and joins four exact source parts from this directory.
- Original 164 module bundle is approximately 4.35 MB.
- This is not live-tested; there are no guarantees of executor compatibility, anti-cheat behavior, or memory stability.

Standalone loadstring:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/CM1potatoman/BookOfTheDepths/main/QuietUI/loader.lua"))()
```
