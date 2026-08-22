# Storage Budget Tracking

**Hard Limit:** 20 GB Max

## Target Allocation & Status
| Category | Budget Target | Current Size | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Source / Project** | 2–3 GB | ~2.5 MB | Normal | GDScript, scenes, networking, UI, configs, materials |
| **Textures & Materials** | 3–4 GB | ~220 MB | Normal | 2K/1K PBR Maps (ambientCG CC0: Tiles130, Ground037, Bricks083, Rocks025, Wood066, Metal009, Leather026, Fabric048) |
| **Environment Assets** | 4–5 GB | ~180 MB | Normal | Poly Haven CC0 photogrammetry models (large_iron_gate, mossy_rocks, fire_pit, crates, barrels) |
| **Characters & Weapons** | 3–4 GB | ~45 MB | Normal | Hero Knight 2K PBR + Antique Estoc + Kite Shield |
| **Audio & VFX** | 1–2 GB | ~0.1 MB | Normal | In-memory procedural SFX synthesizer + GPUParticles3D |
| **Cache & Builds** | 3–4 GB | ~200 MB | Normal | `.godot` cache & imported texture streams |
| **Safety Margin** | ~2 GB | N/A | Available | Buffer to prevent hitting storage ceiling |
| **Total Project** | **20 GB Max** | **~648 MB** | **Healthy** | Monitored via `/perf-check` (3.24% of cap) |
