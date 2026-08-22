# OATHBOUND — Combat Quality & Timing Specifications

## 1. Core Combat Philosophy
> "I am controlling a warrior holding a heavy medieval weapon."

Every melee attack follows a strict 5-stage lifecycle:
```
1. Preparation (Wind-up / Anticipation)
   ↓
2. Acceleration (Blade trajectory movement)
   ↓
3. Contact (Active hitbox frames & hitstop presentation)
   ↓
4. Follow-through (Kinetic inertia dissipation)
   ↓
5. Recovery (Vulnerable recovery or cancel window)
```

---

## 2. Attack Specifications

| Attack Type | Startup (s) | Active Window (s) | Recovery (s) | Base Damage | Poise Dmg | Cancel Window | Hitstop (Client) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Light Attack** | 0.15s | 0.12s | 0.25s | 18.0 | 12.0 | At 0.18s recovery (Dodge/Parry) | 0.03s |
| **Heavy Attack** | 0.35s | 0.15s | 0.40s | 35.0 | 32.0 | At 0.28s recovery (Dodge) | 0.06s |
| **Charged Attack** | 0.45s–1.0s | 0.18s | 0.45s | 45.0–75.0 | 45.0–80.0 | None during release | 0.08s |
| **Finisher Strike**| 0.40s | 0.25s | 0.60s | 120.0 | Instant Kill | None (Cinematic) | 0.10s |

---

## 3. Defense & Reaction Mechanics

### A. Blocking
- **Coverage**: Frontal 160-degree arc.
- **Damage Reduction**: 80% (Knight) / 60% (Berserker) / 50% (Shadow Warrior).
- **Stamina Drain**: Consumes 18.0 stamina per absorbed hit.
- **Guard Break**: If stamina is depleted while blocking, player is put into `StaggeredState` (poise broken) for 1.6s.

### B. Precision Parry
- **Parry Window**: First 0.18s of initiating a block.
- **Parry Reward**: 100% damage nullified, zero stamina cost, electric-blue spark burst, metallic clang audio, and immediate attacker stun for 1.2s.
- **Parry Counter**: Defender gains a 1.5x damage buff on the next immediate attack.

### C. Combat Dodge Roll
- **Duration**: 0.55s total duration.
- **Invulnerability Window**: 0.05s to 0.30s (0.25s total i-frames).
- **Stamina Cost**: 22.0 stamina.
- **Recovery**: 0.25s recovery window before next attack can be initiated.

### D. Hit Reactions
- **Light Hit Reaction**: 0.20s upper body flinch, no displacement.
- **Heavy Hit Reaction**: 0.35s pushback (2.5m displacement) and camera trauma impulse.
- **Poise Break / Stagger**: 1.6s disoriented stumble, exposing target to Finisher.
- **Knockdown**: Target knocked off feet, 1.2s ground duration + 0.6s get-up recovery.

---

## 4. Multiplayer Presentation Hitstop Rules
- **Server Authority**: The authoritative server simulation runs continuously at 60 Hz and never pauses.
- **Client Presentation**: On confirmed hit, the attacking and defending client renderers execute a local 0.03s–0.08s visual micro-freeze on the skeletal mesh and camera trauma shake to convey massive kinetic impact without desynchronizing network state.
