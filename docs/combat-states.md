# OATHBOUND — Combat State Machine Reference

This document defines the 15 combat states, transitions, resource costs, and mechanical rules implemented in `scripts/combat/`.

---

## Combat State Roster

| # | State Name | Script | Category | Trigger / Condition | Duration | Resource Cost | Exit Conditions |
|---|---|---|---|---|---|---|---|
| 1 | **Idle** | `idle_state.gd` | Locomotion | Stationary, no actions | Continuous | None (Regens HP/Stamina/Poise) | Input received |
| 2 | **Movement** | `movement_state.gd` | Locomotion | WASD pressed | Continuous | None | No input, or action triggered |
| 3 | **Sprint** | `sprint_state.gd` | Locomotion | Shift + WASD | Continuous | 18 stamina / sec | Shift released, out of stamina |
| 4 | **LightAttack** | `light_attack_state.gd` | Offensive | LMB Click | 0.55s | 14 Stamina (0 on riposte) | Animation completes -> Idle/Move |
| 5 | **HeavyAttack** | `heavy_attack_state.gd` | Offensive | E key or LMB Release (0.25-0.4s) | 0.85s | 25 Stamina | Animation completes -> Idle/Move |
| 6 | **ChargedAttack** | `charged_attack_state.gd` | Offensive | LMB Hold (>0.4s) | 0.4s–1.2s charge + 0.65s release | 30 Stamina | Release or max charge reached |
| 7 | **Block** | `block_state.gd` | Defensive | RMB Held | Continuous | 15 stamina per hit absorbed | RMB released, Guard break |
| 8 | **Parry** | `parry_state.gd` | Defensive | Hit received ≤ 0.18s of Block | 0.9s (Riposte window) | 8 Stamina | Counterattack executed, or timer |
| 9 | **Dodge** | `dodge_state.gd` | Defensive | Space Key | 0.40s (i-frames: 0.05-0.28s) | 20 Stamina | Roll completes -> Idle/Move |
| 10 | **Ability** | `ability_state.gd` | Supernatural | Q Key | 0.80s cast | Ability energy | Cast completes -> Idle/Move |
| 11 | **Stunned** | `stunned_state.gd` | Crowd Control | Parried by opponent | 0.70s | Involuntary | Timer expires -> Idle |
| 12 | **Staggered** | `staggered_state.gd` | Crowd Control | Poise broken to 0 | 1.00s (Finisher-vulnerable) | Involuntary | Timer expires (Restores Poise) |
| 13 | **KnockedDown** | `knocked_down_state.gd` | Crowd Control | Hit by full Charged Attack | 1.5s down + 0.6s get-up | Involuntary | Recovery completes -> Idle |
| 14 | **Finisher** | `finisher_state.gd` | Execution | F Key near Staggered/Down foe | 1.30s cinematic lock | Involuntary for victim | 85 damage dealt -> Idle |
| 15 | **Dead** | `dead_state.gd` | Terminal | Health reached 0 | Permanent until respawn | None | Respawn / Match End |

---

## Core Combat Systems

### 1. Poise & Stagger System
- Every combatant has a **Poise meter** (default 50.0).
- Light attacks deal **12 Poise damage**, heavy attacks deal **35 Poise damage**, and charged attacks deal up to **60 Poise damage**.
- When Poise drops to 0, the character immediately transitions to **`StaggeredState`**, dropping their guard and becoming open to a **Finisher**.
- Poise begins recovering at 15/sec after 1.5 seconds without taking poise damage.

### 2. Precise Parry & Counterattack Window
- When entering `BlockState`, a precision **Parry Window (0.18s)** opens.
- If an opponent's melee strike connects within this window:
  - 100% of damage and poise damage is negated.
  - The attacker is instantly interrupted and put into **`StunnedState` (0.7s)**.
  - The defender enters **`ParryState` (0.9s riposte window)**.
  - During the riposte window, the defender's next Light Attack costs **0 Stamina** and deals **+50% bonus damage**.

### 3. Charged Attacks & Knockdowns
- Holding attack charges power up to 1.2s.
- Charging past 80% threshold grants **Knockdown capability**.
- Targets struck by a knockdown charged attack transition to **`KnockedDownState`**, falling flat on the ground for 1.5s before standing up.

### 4. Lethal Finisher Execution
- Pressing **`F`** near an opponent who is:
  - In `StaggeredState`, or
  - In `KnockedDownState`, or
  - Below 25% Maximum Health (`finisher_health_threshold`)
- Triggers **`FinisherState`**, locking attacker and victim in a cinematic execution plunge dealing **85.0 lethal damage**.
