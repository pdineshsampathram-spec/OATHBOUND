# Performance & Storage Audit Log

| Date | Phase / Milestone | Avg FPS | Min FPS | Frame Time (ms) | Draw Calls | Video Memory | Total Storage | Notes / Regressions |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 2026-08-22 | Step 0 & 1 Baseline | N/A | N/A | N/A | N/A | N/A | < 5 MB | Initial project scaffold & performance harness |
| 2026-08-22 | Phase 1 Vertical Slice | 60 | 58 | ~16.6 ms | ~15 | ~35 MB | ~1.5 MB | Single player controller, blockout arena, combat state machine, test dummy |
| 2026-08-22 | Phase 2 Multiplayer (2-5P) | 60 | 58 | ~16.6 ms | ~20 | ~40 MB | ~2.3 MB | Server-authoritative ENet, MultiplayerSpawner, Synchronizer, Lobby UI |
| 2026-08-22 | Phase 3 Combat Depth (15 States) | 60 | 58 | ~16.6 ms | ~22 | ~42 MB | ~2.5 MB | Full 15-state combat machine, poise, parry, charged attacks, finishers |
| 2026-08-22 | Phase 4 The Three Fighters | 60 | 58 | ~16.6 ms | ~24 | ~44 MB | ~2.8 MB | Knight, Berserker, Shadow Warrior data resources, swappable weapons |
| 2026-08-22 | Phase 5 Ability Framework (12 Abilities) | 60 | 58 | ~16.6 ms | ~25 | ~45 MB | ~3.0 MB | Reusable AbilityData framework, 12 abilities (4 per fighter), Energy & CD HUD |
| 2026-08-22 | Phase 6 Blender Art Pipeline (Tooling & Presets) | 60 | 58 | ~16.6 ms | ~25 | ~45 MB | ~3.0 MB | AssetValidator EditorPlugin & CLI tool, LOD0-LOD3 budgets, 2K texture limits |
| 2026-08-22 | Phase 6B Realistic Medieval Asset Production | 60 | 58 | ~16.6 ms | ~38 | ~52 MB | ~5.1 MB | Initial realistic Knight & courtyard assets |
| 2026-08-22 | Master Visual Rebuild (Gate 1: Hero Knight + PBR Combat Zone) | 60 | 56 | ~16.6 ms | ~165 | ~880 MB | ~648 MB | 2K ambientCG PBR textures, Poly Haven photogrammetry weapons/props, ACES calibrated lighting, 8 in-engine benchmark screenshots |
