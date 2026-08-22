# OATHBOUND — Project Rules

## Hardware & hard limits
- Dev machine: MacBook Air M1, 8GB unified RAM, 20GB hard storage cap for this project.
- Performance floor: 40 FPS minimum at "Low" quality on this machine. A regression
  below that is a bug, not an acceptable trade-off.
- Engine.max_fps stays capped at 60 with V-Sync on, always.

## Engine & tooling
- Godot 4.4+, Forward+ renderer (switch to Mobile renderer if profiling shows Forward+
  is the bottleneck).
- GDScript by default. Only propose C# for a system that genuinely needs it, and name
  the .NET runtime overhead when you do.
- Assets come from Blender as glTF 2.0 (.glb). Never ask for FBX round-trips.

## Architecture rules
- Server-authoritative multiplayer only. Clients never decide their own damage, hits,
  or deaths.
- Combat is a state machine (see /docs/combat-states.md), not one monolithic
  player-controller script.
- Characters, weapons, and abilities are data-driven (Resource files), not hardcoded
  per-character branches.
- Ship small, independently testable changes. Don't bundle unrelated systems into one
  task.

## Performance & thermal discipline
- Any task adding visual complexity (particles, lights, post-processing, materials)
  reports draw calls, triangle count, and FPS before/after using the in-engine debug
  overlay.
- Never run more than one Godot instance, one Blender instance, and one process-
  spawning agent task at the same time. If a task needs multiple game instances
  (multiplayer testing), say so and get confirmation before launching them.
- Flag any texture import over 2K resolution unless it's an explicitly designated hero
  asset.
- Report current total project folder size after any asset import.

## Documentation
- Log non-trivial architecture decisions to /docs/decisions.md, dated.
- Keep /docs/storage-budget.md updated against this target allocation:
  Source/project 2-3GB, Environment 4-5GB, Characters/animations 3-4GB,
  Textures/materials 3-4GB, Audio/VFX 1-2GB, Cache/build 3-4GB, Safety margin ~2GB.
