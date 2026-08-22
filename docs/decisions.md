# Architecture Decisions Log

## 2026-08-22 — Project Foundation & Scaffolding
- **Engine**: Godot 4.x (Forward+ Renderer default, GDScript).
- **Core Architecture**: Data-driven resources (CharacterData, AbilityData), Server-Authoritative multiplayer (ENetMultiplayerPeer, MultiplayerSpawner, MultiplayerSynchronizer), State Machine combat system.
- **Hardware Profile**: M1 MacBook Air (8GB RAM), strict 20GB project storage limit, 40 FPS floor target at Low quality.
- **Performance Harness**: Always-available autoload `PerformanceOverlay` canvas layer (F3 toggle) tracking FPS, frame time, draw calls, video memory, and object count.
