# Book of the Depths | CM1 Linoria Edition

A Linoria UI conversion of the user-provided 140K-line Book of the Depths Lua bundle.

## Loadstring

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/CM1potatoman/BookOfTheDepths/main/loader.lua"))()
```

The loader joins 14 sequential source parts and validates the full byte count before compiling. Each part is plain text stored under `parts/`. A complete single-file copy is also available outside the repository as `BookOfTheDepths_Linoria_CM1.lua`.

## Changes

- Linoria for the main menu, backed by the official Linoria SaveManager and ThemeManager addons.
- Home tab, CM1/Book of the Depths branding, original feature tab/control IDs, and a groupbox/tabbox compatibility adapter.
- Improved keybind list visibility, watermark visibility inside menus, and optional Bloxstrap RPC fallback on detach.
- Retains original specialized HUD modules using their legacy helpers.

## Limitations

- Original gameplay/timing modules were preserved, not rewritten line-by-line.
- Not tested live in Deepwoken; compilation and executor compatibility are not guaranteed.
- Requires networking, `loadstring`, and all engine/executor interfaces already referenced by the original source.
- The original source contains privileged game hooks and third-party dependencies. Inspect the code before running it.
- Upstream Linoria: https://github.com/violin-suzutsuki/LinoriaLib (MIT license).
