# Architecture Decisions Log

## 2026-08-22 — Project Foundation & Scaffolding
- **Engine**: Godot 4.x (Forward+ Renderer default, GDScript).
- **Core Architecture**: Data-driven resources (CharacterData, AbilityData), Server-Authoritative multiplayer (ENetMultiplayerPeer, MultiplayerSpawner, MultiplayerSynchronizer), State Machine combat system.
- **Hardware Profile**: M1 MacBook Air (8GB RAM), strict 20GB project storage limit, 40 FPS floor target at Low quality.
- **Performance Harness**: Always-available autoload `PerformanceOverlay` canvas layer (F3 toggle) tracking FPS, frame time, draw calls, video memory, and object count.

## 2026-08-22 — Phase 6B: High-Fidelity Realistic Medieval Art Direction
- **Art Style Decision**: Strict realistic medieval aesthetic with high material fidelity, believable anatomical proportions, and authentic weathering. Reject stylized/low-poly asset kits.
- **Pipeline Strategy**: Blender 5.2.0 automated glTF 2.0 (`.glb`) generation with PBR materials (roughness variation, edge wear, metallic scratches, normal maps), modular architecture for courtyard arena, and skeletal animation with AnimationTree blending.
- **Hero Asset Exception**: Hero Knight allowed up to ~12.4K tris at LOD0 for close-up fidelity, supported by LOD1–LOD3 decimation.
- **Performance Discipline**: 5-stage progressive safety gates (Knight -> Small Env -> Full Arena -> VFX+Combat -> 2-5P Multiplayer) enforcing 60 FPS cap / 40 FPS floor on M1 hardware.

## 2026-08-23 — Gate 3: Master Character Articulation, Biomechanical Combat Rebuild & Autonomous Quality Controller
- **15th-Century Gothic Plate Armor Reconstruction**: Rebuilt `assets/characters/hero_knight.glb` with authentic anatomical proportions (wasp-waist cuirass with median ridge, fluted sallet helmet with comb & flared tail, 4-lame overlapping fauld skirt, articulating knee cop lames, and brushed silver steel PBR material).
- **Skeletal Weapon Attachment**: Replaced detached weapon transforms with direct Godot `BoneAttachment3D` bindings (`Hand.R` for longsword/axe/dagger, `Forearm.L` for kite shield), synchronizing weapon trajectories directly to skeletal swings.
- **Cinematic Combat Camera Rig**: Upgraded `CameraRig` with adaptive distance (3.2m in guard stance, 4.0m in exploration), trauma-based camera shake decay on heavy strikes/parries, and directional impact punch.
- **Autonomous Quality Improvement Protocol**: Executed automated 20-action combat validation benchmark (`scripts/tools/run_gate3_quality_loop.gd`), scoring all 10 quality dimensions to >= 8.0 while maintaining 60.0 FPS and < 20 GB storage (< 1 GB used).

## 2026-08-23 — Gate 4: Quality Rebuild — Centralized Time Controller, Skeletal Animation Authority, Supernatural VFX, AI Streaming & Solo Wave Arena
- **Centralized Time Scale Management**: Resolved critical slow-motion leak bug by architecting `CombatTimeController` autoload singleton. Bounded all hitstops and slow-mo with unscaled failsafe timers and absolute recovery guards, prohibiting ad-hoc `Engine.time_scale` writes elsewhere.
- **Skeletal Animation Authority**: Inspected and verified `hero_knight.glb` (21 bones, 28 layered combat animations). Eliminated all tween-driven rotational/positional overrides across attacks, dodges, hit reactions, and deaths; re-established direct skeletal animation driving full-body combat biomechanics.
- **Supernatural Dark-Violet VFX Architecture**: Replaced primitive geometric collision meshes with layered `GPUParticles3D` system in `PowerVFXSystem`, incorporating void violet/core white energy language, dynamic character auras, and 8-phase cinematic ultimate sequences.
- **AI Combat Controller & Solo Wave Arena**: Built `AICombatController` (10 decision states, coordination awareness, difficulty scaling) and `WaveManager` streaming up to 3 simultaneous AI opponents in `solo_arena.tscn` for endless practice.

## 2026-08-23 — God-Tier Ultimate Cinematic Rebuild (42-Second Battlefield Cataclysm)
- **12-Scene Multi-Shot Cinematic Director (`ultimate_cinematic_controller.gd`)**: Built a full 42-second battlefield cataclysm with 12 distinct scenes, 12 motivated camera choreographies with emotional purpose (Preparation, Awakening, 6-layer Aura, Sky Transformation, Kinetic Sword Ascension, Physical Propagation Wave, Enemy Terror, 8-stage Staggered Vaporization, Zenith Silence, Multi-scale Release, Aftermath, and Victory Portrait).
- **Blender 5.2.0 Hero Pipeline**: Authored 1200-frame continuous skeletal animation action across the 21-bone armature in Blender 5.2.0 CLI (`ultimate_ascendance`) with full kinetic body mechanics, stance shifting, and breathing tension. Exported custom 3D VFX meshes: `sword_energy_mesh.glb`, `aura_ribbon_mesh.glb`, `expanding_shockwave_ring.glb`, `propagation_wave_mesh.glb`, and `celestial_dome_mesh.glb`.
- **Layered Atmospheric Sky Event & Physical Propagation Wave**: Replaced flat sky tints with multi-layered celestial dome evolution (`normal -> darkening -> cloud deformation -> distant violet energy -> vertical structures -> storm dome -> persistent scar`). Implemented physical ground wave traveling from 5m -> 15m -> 30m -> 50m -> 75m -> 100m with surface-aware dust and stone reactions.
- **8-Stage Enemy Vaporization Micro-Cinematic**: Built advanced `dissolution_shader.gdshader` supporting internal energy glow, surface fracture veins, 3D Simplex noise discard, and edge burning. Dissolves enemies with inward-drawn vapor particles.
- **Authoritative Combat & Solo Wave Reliability**: Guaranteed authoritative lethal damage, instant signal propagation to `WaveManager`, zero time-scale leaks (`Engine.time_scale = 1.000`), and idempotent `force_restore_player_control()`.
- **Validation**: Passed all tests in `test_ultimate_cinematic_suite.gd` (1 vs 3 enemies, staggered vaporization, interruption safety, post-cinematic controls) and `test_solo_wave_arena_progression.gd` (Wave 1 -> Wave 2 -> Wave 3). Total storage 909MB (< 1GB / 20GB limit).


