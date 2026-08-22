# Storage Budget Tracking

**Hard Limit:** 20 GB Max

## Target Allocation
| Category | Budget Target | Current Size | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Source / Project** | 2–3 GB | < 50 MB | Normal | GDScript, scenes, configs |
| **Environment Assets** | 4–5 GB | 0 MB | Normal | Modular props, castle blockout/geometry |
| **Characters & Animations** | 3–4 GB | 0 MB | Normal | Knight, Berserker, Shadow Warrior |
| **Textures & Materials** | 3–4 GB | 0 MB | Normal | PBR textures, max 2K unless hero asset |
| **Audio & VFX** | 1–2 GB | 0 MB | Normal | Particle shaders, combat SFX |
| **Cache & Builds** | 3–4 GB | 0 MB | Normal | `.godot` cache, temp exports |
| **Safety Margin** | ~2 GB | N/A | Available | Buffer to prevent hitting storage ceiling |
| **Total Project** | **20 GB Max** | **~1 MB** | **Healthy** | Monitored via `/perf-check` |
