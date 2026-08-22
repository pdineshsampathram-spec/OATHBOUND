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
