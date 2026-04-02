# Reight

Retro game engine with a built-in IDE for editing sprites, maps, and sounds.

## CLI

```bash
r8 --edit .   # Launch the editor
```

## Built-in Editors

- **SpriteEditor** (`app/sprite/`) — Pixel art editor with brush, fill, select, and shape tools
- **MapEditor** (`app/map/`) — Chunk-based tile map editor
- **SoundEditor** (`app/sound/`) — Waveform-based sound editor

Each editor inherits from the `App` base class and uses the Tool pattern to switch drawing tools.

## Project Data

Managed as JSON files:
- `project.json` — Project settings
- `chips.json` — Tileset
- `maps.json` — Map data
- `sounds.json` — Sound data

## Constants

- Screen resolution: 400x224
- Palette: 32 colors (`PALETTE_COLORS`)
- Sprite size: 8x8 pixel units
