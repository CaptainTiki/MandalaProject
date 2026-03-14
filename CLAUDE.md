# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Directives

### **Code** - all code should be written in a human readabld, verbose manner

## Project

**Sigil Engine** — a meditative incremental game (game jam, 1-month scope) built in Godot 4.6 with GDScript. Full design spec is in `SigilEngine_GDD.md`.

Core loop: place geometric shapes on a rotationally-symmetric Mandala → shapes generate resources → shape combinations discover Sigils → Sigils multiply output → archive Mandala when saturated → repeat with legacy Flux carrying forward → win by reaching Convergence threshold.

## Running

```bash
# Open project in editor
godot --path D:/godot/repos/MandalaProject

# Run directly
godot --path D:/godot/repos/MandalaProject --

# Run a specific scene
godot --path D:/godot/repos/MandalaProject res://scenes/main.tscn
```

No build step — Godot projects run from source. The `.godot/` directory is auto-generated cache; never edit it manually.

## Engine Configuration

- Language: GDScript exclusively
- Renderer: GL Compatibility (GLES3) — cross-platform
- Physics: Jolt (3D, though game is 2D)
- Graphics driver (Windows): Direct3D 12
- Target: PC (Windows / Mac / Linux)

## Architecture

### Core Data Model

The central type is `MandalaPiece` (from GDD §14):

```gdscript
class_name MandalaPiece
var shape_type: String       # triangle, square, pentagon, hexagon, octagon
var color_tier: String       # grey, blue, red, purple, gold
var size_tier: String        # small, normal, large, vast
var position: Vector2        # world position
var rotation: float          # radians
var symmetry_index: int      # 0 = canonical Arm 0; 1..N-1 = mirror arms
var open_edges: Array        # Edge objects available for placement
var neighbors: Array         # connected MandalaPiece references
var active_sigils: Array     # Sigil instances this piece participates in
```

### Symmetry System

The Mandala's symmetry order N (3/4/5/6) is set by the center shape chosen at run start. Player only interacts with **Arm 0**; all other arms are display-only mirrors with no hit detection or Sigil logic.

Mirror math: `mirror_pos = arm0_pos.rotated((2 * PI / N) * i)` for arm index `i`.

### Key Systems

| System | Implementation notes |
|---|---|
| Adjacency graph | Shared-edge detection between Polygon2D nodes using edge midpoint proximity. Each piece tracks `neighbors`. |
| Sigil detection | Runs after every placement on Arm 0 only. Scans local neighborhood against Sigil registry. Mirror arms inherit Sigil state. |
| Multi-Sigil stacking | First membership = 100%, second = 75%, third = 50%, further = 25%. Intersection-trait Sigils ignore this. |
| Chromatic Dissonance | Each same-color neighbor subtracts 0.15x from the piece's color multiplier. |
| Chromatic Resonance | All neighbors different colors from each other and the piece = +0.3x bonus. |
| Animations | Tween nodes for pulse/glow cycles; ShaderMaterial for color saturation and glow intensity. |
| Camera | Camera2D with position lerp for pan inertia; zoom lerped 0.3x–3.0x. |
| Starfield | 2–3 Node2D layers of small circle polygons at differing scroll speeds + mouse-parallax tilt. |
| Persistence | Resonance, Tome, unlocks, and archived Mandala data saved to JSON via `FileAccess`. |

### Resources

| Resource | Resets on prestige | Role |
|---|---|---|
| Aether | Yes | Moment-to-moment spend currency |
| Flux | No (archived Mandalas keep generating) | Long-term win-condition meter |
| Resonance | Never | Permanent meta-progression unlock currency |

### Sigil Categories

- **Shape Sigils**: specific polygon combination, color irrelevant → flat generators or output multipliers
- **Color Sigils**: specific color pattern, shape irrelevant → new generation or discount effects
- **Compound Sigils**: specific shape AND color → rare, powerful, unique effects

Target: 15–20 total discoverable Sigils. Sparkle hints appear on Arm 0 edges only for already-discovered (Tome-recorded) Sigils.

## Development Phases (from GDD §13)

1. **Week 1 — Living Mandala**: Rendering, symmetry math, edge detection, placement, shape/color selector, shader animations, starfield, camera
2. **Week 2 — Economy**: Aether generation, shop panel, cost model (symmetry multiplier, color costs), Chromatic Dissonance/Resonance
3. **Week 3 — Sigils & Tome**: Adjacency graph, Sigil detection/effects, Tome UI, sparkle hints, Resonance rewards
4. **Week 4 — Prestige & Polish**: Archive mechanic, background Mandala rendering, persistent unlock shop, Convergence endgame, audio, juice pass

## Folder Structure

```
gameplay/
  mandala/     # Mandala board, symmetry, edge detection
  shapes/      # MandalaPiece, shape rendering
  sigils/      # Sigil registry, detection, effects
  tome/        # Tome UI and discovery records
  hud/         # In-run UI (resource counters, shop)
system/
  main/        # Main scene, bootstrapping
  globals/     # Autoloads / singletons
assets/
  shaders/     # ShaderMaterial files
  sprites/
  textures/
menus/
audio/
  music/
  sfx/
docs/          # GDD and design documentation
```

## Open Design Questions

See GDD §15 for unresolved items: final Sigil list, Convergence threshold tuning, Scholar Rank system, sound direction, archived Mandala layout, tutorial approach, center shape selection UI.
