# Combat State Machine Architecture

## Overview
OATHBOUND uses a modular, discrete state machine pattern (`StateMachine` node with per-state `State` node objects) rather than a monolithic script.

## Combat States (Planned)
- **Idle**: Grounded, stationary, recovering stamina.
- **Movement**: Grounded walk/run, stamina regeneration active.
- **Sprint**: Fast movement, drains stamina over time.
- **LightAttack**: Fast sword strike with low stamina cost, combo chaining.
- **HeavyAttack**: Slower attack with higher damage and poise damage / stagger.
- **ChargedAttack**: High-risk, high-reward chargeable strike.
- **Block**: Raised guard, consumes stamina on hit absorption, reduces chip damage.
- **Parry**: Precise timing window upon incoming hit, triggers attacker stagger / counter window.
- **Dodge**: Directional roll / evasive dash with invulnerability frames (i-frames).
- **Ability**: Special power execution (Offensive, Defensive, Mobility, Control, Ultimate).
- **Stunned**: Incapacitated by control ability or guard break.
- **Staggered**: Interrupted briefly by heavy blow.
- **KnockedDown**: Grounded recovery state.
- **Finisher**: Cinematic execution state against critical/vulnerable target.
- **Dead**: Health reaching 0, ragdoll/death animation, server authoritative despawn.
