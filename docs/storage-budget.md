# Storage Budget Tracking

**Hard Limit:** 20 GB Max

## Target Allocation & Status
| Category | Budget Target | Current Size | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Source / Project** | 2–3 GB | ~3.8 MB | Normal | GDScript, scenes, networking, UI, configs, materials |
| **Textures & Materials** | 3–4 GB | ~280 MB | Normal | 2K/1K PBR Maps (Tiles130, Ground037, Bricks083, Rocks025, Wood066, Metal009, Leather026, Fabric048) |
| **Environment Assets** | 4–5 GB | ~220 MB | Normal | 100m Ruined Fortress Arena + Poly Haven CC0 photogrammetry models |
| **Characters & Weapons** | 3–4 GB | ~75 MB | Normal | Hero Knight 2K PBR + 28-action biomechanical combat suite + Antique Estoc + Kite Shield |
| **Audio & VFX** | 1–2 GB | ~0.1 MB | Normal | In-memory procedural SFX synthesizer + GPUParticles3D |
| **Cache & Builds** | 3–4 GB | ~400 MB | Normal | `.godot` cache & imported texture streams |
| **Safety Margin** | ~2 GB | N/A | Available | Buffer to prevent hitting storage ceiling |
| **Total Project** | **20 GB Max** | **~978 MB** | **Healthy** | Monitored via `/perf-check` (4.89% of cap, 19.02 GB headroom) |
