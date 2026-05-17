# SekretovOS

Industrial SCADA-style operating environment for **OpenComputers / OpenOS** (Lua 5.2).

## Install

1. Copy the entire `SekretovOS` folder to your computer (e.g. `/SekretovOS`).
2. Requires: **GPU**, **Screen**, tier 2+ recommended.
3. Run:

```lua
cd /SekretovOS
main
```

Or: `lua /SekretovOS/main.lua`

## Controls

| Input | Action |
|-------|--------|
| `L` | Application launcher |
| Click clock (top-right) | Toggle launcher |
| Arrow / W-S in launcher | Select app |
| Enter | Launch app |
| Drag title bar | Move window |
| Click `[X]` | Close window |
| Ctrl+C | Shutdown |

## Architecture

```
main.lua          → boot, load apps, start kernel loop
system/kernel.lua → boot, module registry, main loop
system/render.lua → double buffer + dirty rects
system/gui.lua    → widgets API
system/window.lua → WM: focus, z-index, drag
system/desktop.lua→ wallpaper, top bar, launcher
system/events.lua → normalized input
system/theme.lua  → palettes
system/services.lua → logs, telemetry, config
apps/*.lua        → applications
```

## API (summary)

### GUI

- `gui.window(opts)` — `{ title, x, y, w, h, onDraw, onClose }`
- `gui.button(opts)` — `{ text, onClick }`
- `gui.label(opts)` — `{ text, align, color }`
- `gui.panel(opts)`
- `gui.graph(opts)` — `{ data, minVal, maxVal }`
- `gui.renderGraph(x, y, w, h, data, opts)`
- `gui.progressBar(opts)` — `{ value, max, label }`
- `gui.tabs(opts)` — `{ tabs, active, onTab }`
- `gui.notify(title, msg, level)`

### Theme

- `theme.apply("industrial" | "cyberpunk" | "retro")`
- `theme.current.background`, `.panel`, `.accent`, `.warning`, `.success`, `.error`

### Services

- `services.info(warn|error|alert)(source, message)`
- `services.getEnergy()`, `getAE2()`, `getReactor()`
- `services.saveConfig(key, value)`

## Extending

Create `apps/myapp.lua`:

```lua
local _OS = _OS
local gui, render = _OS.gui, _OS.render

return {
  id = "myapp",
  name = "My App",
  createWindow = function()
    return gui.window({
      title = "MY APP",
      x = 5, y = 5, w = 40, h = 12,
      onDraw = function(ax, ay, ww, wh) end,
    })
  end,
}
```

Add `"myapp"` to `appIds` in `main.lua`.

Telemetry in `services.lua` is mock data — replace `tickTelemetry()` with real component probes (energy bridge, ME grid, reactor adapter).

## License

MIT — use freely in modpacks and servers.
