# Storage Budget Tracking

**Hard Limit:** 20 GB Max

## Target Allocation & Status
| Category | Budget Target | Current Size | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Source / Project** | 2–3 GB | ~4.5 MB | Normal | GDScript, scenes, networking, UI, configs, materials, 11 shaders |
| **Textures & Materials** | 3–4 GB | ~280 MB | Normal | 2K/1K PBR Maps (Tiles130, Ground037, Bricks083, Rocks025, Wood066, Metal009, Leather026, Fabric048) |
| **Environment Assets** | 4–5 GB | ~220 MB | Normal | 100m Ruined Fortress Arena + Poly Haven CC0 photogrammetry models |
| **Characters & Weapons** | 3–4 GB | ~85 MB | Normal | Hero Knight 2K PBR + 15-action cinematic combat suite (8 knight + 7 enemy) + Antique Estoc + Kite Shield |
| **Audio & VFX** | 1–2 GB | ~0.2 MB | Normal | In-memory procedural SFX synthesizer + GPUParticles3D + 5 new art-first shaders |
| **Cache & Builds** | 3–4 GB | ~400 MB | Normal | `.godot` cache & imported texture streams |
| **Safety Margin** | ~2 GB | N/A | Available | Buffer to prevent hitting storage ceiling |
| **Total Project** | **20 GB Max** | **~1.2 GB** | **Healthy** | 6.0% of cap, 18.8 GB headroom. Measured 2026-08-25 |
