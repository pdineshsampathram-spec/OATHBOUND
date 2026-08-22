# OATHBOUND — Master Game Development Prompt

## Project Vision

Develop a scalable **3D multiplayer medieval fantasy arena fighting game** called **OATHBOUND**, focused on intense close-quarters combat, supernatural powers, distinct fighting styles, and a highly atmospheric medieval environment.

The game must be designed from the beginning as a **modular, scalable multiplayer project**, while keeping the first playable version small enough to develop and test comfortably on a laptop with limited hardware and storage.

The first version should prioritize:

**Excellent combat feel + stable multiplayer + strong visual quality + aggressive optimization**

Do not attempt to build a massive open-world game in Version 1.

---

## 1. Hardware and Storage Constraints

The development environment has:

- Apple M1 MacBook Air
- 8 GB RAM
- Approximately 90 GB currently free
- Only **20 GB of the available storage may be used by this game project**

The remaining storage must not be consumed by the project.

Treat **20 GB as a hard project-storage budget**.

The project must therefore use:

- optimized assets
- shared materials
- texture reuse
- LODs
- instancing
- compressed assets
- controlled caches
- minimal duplicate files
- regular cleanup of temporary files
- no unnecessary asset packs

Do not design the project assuming unlimited storage, RAM, or GPU power.

---

## 2. Visual Target

The game should have a **photorealistic medieval fantasy visual style**.

The desired visual characteristics are:

- realistic stone
- weathered wood
- rusted metal
- realistic cloth
- realistic armor
- detailed weapons
- physically based materials
- atmospheric fog
- realistic fire
- cinematic environments
- natural vegetation
- believable weathering
- detailed lighting
- realistic character materials

However, photorealism must be achieved through **efficient asset creation and rendering**, not brute-force hardware usage.

The game should support a scalable quality system.

### Quality targets

#### Low

- 1080p-oriented rendering
- optimized textures
- simplified effects
- lower foliage density
- reduced lighting complexity

#### Medium

- 1080p/1440p-oriented rendering
- higher-quality textures
- improved shadows
- improved effects
- moderate environment density

#### High

- high-quality output capable of appearing 4K
- high-quality hero textures
- improved lighting
- enhanced VFX
- higher environment detail

Do not require native 4K rendering for the development laptop.

The goal is **4K-quality visual presentation where hardware permits**, not forcing every machine to render native 4K.

---

# 3. Game Format

The core game is a:

**Third-person multiplayer medieval fantasy arena fighter.**

Players fight inside a confined combat arena.

### Player count

Minimum:

**2 players**

Maximum:

**5 players**

The first game mode should be:

### Free For All

Every player fights every other player.

The last surviving player wins.

The networking architecture must be designed so that future modes can be added without rewriting the core multiplayer system.

Future possibilities:

- 1v1
- 2v2
- 3v3
- Team Deathmatch
- King of the Arena
- Capture the Relic
- PvE boss battles
- Tournament mode

---

# 4. Initial Version Scope

Version 1 should contain:

### Characters

3 playable fighters.

### Fighter 1 — Knight

Weapon:

**Long sword + shield**

Combat identity:

- defense
- parrying
- counterattacks
- balanced movement
- reliable damage

### Fighter 2 — Berserker

Weapon:

**Great axe**

Combat identity:

- heavy attacks
- high stagger
- armor breaking
- powerful area attacks
- aggressive play

### Fighter 3 — Shadow Warrior

Weapons:

**Dual blades**

Combat identity:

- speed
- mobility
- rapid combos
- evasive movement
- burst damage

---

# 5. Arena

Version 1 should contain **one highly polished medieval arena**.

Working environment:

## Ruined Medieval Castle Courtyard

The arena should contain:

- ruined castle walls
- stone floor
- broken towers
- wooden platforms
- stairs
- pillars
- banners
- torches
- fire pits
- broken carts
- siege equipment
- statues
- vegetation
- mud
- puddles
- atmospheric fog
- environmental debris

The initial arena should be relatively compact rather than a huge open world.

Target approximately:

**40m × 40m combat space**

with some vertical variation.

The arena should support meaningful positioning and movement.

---

# 6. Arena Gameplay

The environment must support combat rather than simply acting as decoration.

Possible environmental elements include:

### Pillars

Can provide temporary cover.

### Fire

Deals damage over time.

### Mud

Reduces movement speed.

### Elevated platforms

Provide positional advantages.

### Breakable objects

Can be destroyed during combat.

### Environmental hazards

Can interact with abilities and attacks.

The environment should eventually support:

**player vs player vs environment**

rather than only player-vs-player combat.

Do not make environmental destruction overly expensive in Version 1.

Use limited, controlled breakable objects.

---

# 7. Core Combat Philosophy

Combat must feel:

- responsive
- readable
- skill-based
- weighty
- tactical
- satisfying
- easy to understand but difficult to master

The player should win because of:

- timing
- positioning
- stamina management
- attack selection
- defensive reactions
- ability usage
- movement

not simply because of higher statistics.

---

# 8. Combat System

Each character should have:

- health
- stamina
- poise/stagger resistance
- attack power
- defense
- movement speed
- supernatural energy/resource

Combat should support:

### Light attacks

Fast attacks with low stamina cost.

### Heavy attacks

Slower attacks with greater damage and stagger.

### Charged attacks

High-risk, high-reward attacks.

### Blocking

Reduces incoming damage.

### Parrying

Precisely timed defense that creates an opportunity for a counterattack.

### Dodging

Short evasive movement.

### Stagger

Powerful attacks can interrupt opponents.

### Knockdown

Certain attacks can knock players down.

### Finisher

A defeated or heavily staggered enemy can eventually be finished with a cinematic attack.

---

# 9. Combat State Machine

Create a reusable combat state architecture.

Possible states:

```text
Idle
Movement
Sprint
LightAttack
HeavyAttack
ChargedAttack
Block
Parry
Dodge
Ability
Stunned
Staggered
KnockedDown
Finisher
Dead
```

Transitions must be controlled and deterministic.

Avoid creating one enormous hardcoded combat script.

The combat system must be modular.

---

# 10. Stamina System

Stamina is a core combat resource.

Actions consume stamina:

- sprinting
- dodging
- blocking
- heavy attacks
- special actions

The player should be punished for continuously attacking without thinking.

The combat loop should encourage:

**Attack → defend → reposition → recover → attack again**

Stamina regeneration should be carefully balanced.

---

# 11. Fighting Styles

Every fighter must feel mechanically different.

Do not create three identical characters with different damage values.

## Knight — Sentinel

Strengths:

- defense
- parry
- shield
- counters

Weakness:

- slower mobility

Combat loop:

```text
Block
→ Parry
→ Counter
→ Shield Bash
→ Finisher
```

---

## Berserker — Ravager

Strengths:

- damage
- stagger
- armor breaking

Weaknesses:

- slower attacks
- weaker defense

Combat loop:

```text
Dodge
→ Heavy Attack
→ Stagger
→ Rage
→ Finisher
```

---

## Shadow Warrior — Phantom

Strengths:

- speed
- mobility
- combo potential

Weaknesses:

- lower durability

Combat loop:

```text
Dash
→ Combo
→ Dodge
→ Reposition
→ Back Attack
→ Burst
```

---

# 12. Supernatural Power System

The game should combine realistic medieval combat with supernatural abilities.

Each character should have:

- Ability 1
- Ability 2
- Ability 3
- Ultimate

Abilities must have:

- cooldowns
- costs
- animations
- VFX
- SFX
- ranges
- damage/effects
- states/interactions

---

# 13. Example Abilities

## Knight

### Holy Guard

Creates a temporary defensive barrier.

### Judgement Strike

Powerful sword attack.

### Shield Rush

Charges into an enemy.

### Ultimate — Divine Execution

Temporarily empowers the Knight and enables a devastating finishing attack.

---

## Berserker

### Blood Rage

Temporarily increases offensive power.

### Ground Breaker

Creates a shockwave around the Berserker.

### Axe Throw

Long-range attack.

### Ultimate — Wrath

A powerful area attack with dramatic visual impact.

---

## Shadow Warrior

### Shadow Step

Short teleport/dash.

### Smoke Veil

Creates concealment.

### Blade Storm

Rapid sequence of attacks.

### Ultimate — Death From Shadow

Rapidly attacks nearby enemies from multiple positions.

---

# 14. Ability Architecture

Do not hardcode abilities directly into individual characters.

Create a reusable ability framework.

Conceptually:

```text
AbilityBase
    ├── OffensiveAbility
    ├── DefensiveAbility
    ├── MobilityAbility
    ├── ControlAbility
    └── UltimateAbility
```

Every ability should be data-driven.

Ability data should include:

```text
Damage
Cooldown
ResourceCost
Range
Area
CastTime
Animation
VFX
SFX
StatusEffects
```

This should allow new abilities to be created without rewriting the underlying combat architecture.

---

# 15. Character Architecture

Create a reusable base character.

Conceptually:

```text
BaseCharacter
    ├── Knight
    ├── Berserker
    └── Shadow Warrior
```

The base character should contain common systems such as:

- movement
- health
- stamina
- combat
- abilities
- animation
- interaction
- multiplayer replication

Character-specific behaviour should be implemented as configurable data and modular components wherever possible.

---

# 16. Data-Driven Design

Characters, weapons, abilities, and balancing values should be data-driven.

Example:

```text
CharacterData
    Health
    Stamina
    Speed
    Armor
    Weapon
    Abilities
    Animations
```

Example:

```text
AbilityData
    Damage
    Cooldown
    Cost
    Range
    Animation
    VFX
    SFX
```

This is essential for future balancing and expansion.

---

# 17. Multiplayer Architecture

Use a **server-authoritative multiplayer architecture**.

The server must control:

- player state
- damage
- health
- ability activation
- hit validation
- deaths
- match state
- win conditions

Clients should primarily handle:

- input
- local responsiveness
- camera
- interface
- visual presentation

Example combat flow:

```text
Client Input
      ↓
Attack Request
      ↓
Server Validation
      ↓
Hit Detection
      ↓
Damage Calculation
      ↓
Server State Update
      ↓
Replication
      ↓
All Players See Result
```

Do not trust clients to decide their own damage or hits.

---

# 18. Match Flow

The match structure should be:

```text
Main Menu
↓
Lobby
↓
Character Selection
↓
Arena Loading
↓
Player Spawn
↓
Countdown
↓
Combat
↓
Winner Determination
↓
Results Screen
↓
Rematch
```

The architecture must support future matchmaking and dedicated/server-hosted configurations without redesigning the gameplay framework.

---

# 19. Camera

Use a:

**third-person combat camera**

Features should eventually include:

- smooth movement
- target awareness
- optional target lock
- collision handling
- enemy framing
- camera shake
- strong hit feedback
- cinematic finisher camera

The camera must always maintain strong spatial readability.

Players should easily understand:

- their position
- enemy position
- attack direction
- arena boundaries

---

# 20. Blender Asset Pipeline

Blender should be used for:

- environment modelling
- character modelling
- weapons
- props
- materials
- UV work
- asset preparation
- animation preparation where appropriate

Build the environment in stages.

### Stage 1 — Blockout

Use simple geometry for:

- walls
- floor
- towers
- platforms
- spawn points
- combat boundaries

Goal:

**prove gameplay first.**

### Stage 2 — Structural Assets

Create:

- castle walls
- floors
- gates
- stairs
- pillars
- wooden structures

### Stage 3 — Hero Assets

Create:

- statues
- major gates
- siege equipment
- special props
- major environmental landmarks

### Stage 4 — Surface Detail

Add:

- cracks
- moss
- dirt
- rust
- scratches
- blood
- weathering

### Stage 5 — Vegetation

Use optimized instances for:

- grass
- bushes
- ivy
- trees

Avoid thousands of unique high-poly meshes.

---

# 21. Character Production Pipeline

Each character should contain:

### Model

- body
- armor
- clothing
- accessories
- weapon

### Materials

Use physically based materials with:

- Base Color
- Normal
- Roughness
- Metallic
- Ambient Occlusion where appropriate

### Rig

Use a reusable humanoid skeleton where practical.

### Animation

At minimum:

- idle
- walk
- run
- sprint
- dodge
- block
- parry
- light attacks
- heavy attack
- hit reaction
- stagger
- knockdown
- recovery
- death
- abilities
- finisher

---

# 22. Asset Optimization

Optimization is part of the art pipeline, not something added at the end.

Use:

### LODs

```text
LOD0 = highest detail
LOD1 = medium
LOD2 = low
LOD3 = very low
```

Use high detail only when the camera is close enough to benefit from it.

Use texture sizes intelligently.

### 4K

Only for:

- hero characters
- hero weapons
- major visual assets

### 2K

For most important environment assets.

### 1K

For small/repeated props.

Use shared materials whenever possible.

Use instancing for repeated objects.

---

# 23. Storage Budget

The entire project must stay within approximately:

## 20 GB maximum

Target allocation:

```text
Source/project files       2–3 GB
Environment assets         4–5 GB
Characters/animations      3–4 GB
Textures/materials         3–4 GB
Audio/VFX                  1–2 GB
Cache/build files          3–4 GB
Safety margin              ~2 GB
```

Avoid storing:

- unused asset packs
- duplicate textures
- unnecessary exports
- old builds
- unused cache files
- giant raw datasets
- unnecessary temporary renders

Use regular project cleanup.

---

# 24. Performance Target

The game should prioritize stable gameplay on the available laptop.

Target:

### Minimum practical development target

**~40 FPS**

The project must use scalable quality settings.

Performance optimization should monitor:

- GPU utilization
- CPU usage
- RAM
- VRAM/system memory
- frame time
- draw calls
- triangle count
- texture memory
- shader complexity
- network traffic

Do not sacrifice gameplay responsiveness merely to achieve visual effects.

---

# 25. Development Philosophy

Build the game as a **vertical slice first**.

Do not begin by creating the entire final environment.

The first prototype should contain:

```text
1 character
1 weapon
1 small arena blockout
Movement
Attack
Block
Parry
Dodge
Health
Death
```

Then add:

```text
2-player multiplayer
```

Then:

```text
3 fighters
```

Then:

```text
Abilities
```

Then:

```text
5-player testing
```

Then:

```text
Photorealistic environment
```

Then:

```text
Polish + optimization
```

---

# 26. Development Sequence

### Phase 1 — Prototype

Build:

- movement
- camera
- sword combat
- health
- stamina
- block
- dodge
- hit detection

### Phase 2 — Multiplayer

Build:

- server authority
- player spawning
- 2-player combat
- replication
- health synchronization
- death
- match restart

Then verify:

**2 → 3 → 4 → 5 players**

### Phase 3 — Combat Depth

Add:

- parrying
- stagger
- combos
- heavy attacks
- knockdown
- finishers

### Phase 4 — Fighters

Implement:

- Knight
- Berserker
- Shadow Warrior

### Phase 5 — Powers

Implement the ability framework and character abilities.

### Phase 6 — Visual Production

Create the final medieval arena in Blender and integrate the optimized assets.

### Phase 7 — Optimization

Profile and optimize the complete vertical slice.

### Phase 8 — Polish

Add:

- UI
- audio
- VFX
- environmental effects
- camera effects
- menus
- lobby
- match results
- final feedback systems

---

# 27. Antigravity Development Role

Antigravity should act as a structured development assistant rather than attempting to build everything in one operation.

Create separate responsibilities such as:

### Combat Engineer

Responsible for:

- combat state machine
- attacks
- hit detection
- damage
- stamina
- parry
- block
- combos

### Multiplayer Engineer

Responsible for:

- replication
- player spawning
- match flow
- lobby
- server authority
- synchronization

### Ability Engineer

Responsible for:

- ability framework
- cooldowns
- resources
- status effects
- ultimates

### Art Pipeline Engineer

Responsible for:

- asset validation
- naming conventions
- LOD validation
- texture validation
- import consistency
- storage monitoring

### QA/Performance Engineer

Responsible for:

- performance tests
- multiplayer tests
- combat tests
- regression testing
- memory usage
- frame-time monitoring
- storage monitoring

Agents must make **small, testable changes**, avoid unnecessary rewrites, document architectural decisions, and verify their work before modifying unrelated systems.

---

# 28. Scalability Requirement

The architecture must allow future expansion to:

- more characters
- more weapons
- more abilities
- more arenas
- more game modes
- team battles
- PvE
- bosses
- destructible elements
- progression
- customization
- cosmetics

without requiring a rewrite of the fundamental combat or multiplayer architecture.

---

# 29. First Milestone

The first milestone is **not** photorealistic graphics.

The first milestone is:

## Two players successfully fighting each other in a small medieval arena.

It must support:

- movement
- camera
- sword attacks
- blocking
- dodging
- health
- stamina
- hit detection
- damage
- death
- multiplayer synchronization
- stable gameplay

Once that works reliably, increase visual quality.

---

# 30. Final Design Principle

Build OATHBOUND using this philosophy:

**Small in content. Strong in architecture.**

Do not create a massive game immediately.

Create a highly polished **2–5 player medieval supernatural combat vertical slice**, with modular systems and optimized assets.

The final experience should feel like:

> Five warriors enter a ruined medieval fortress.  
> Steel clashes against steel.  
> Players dodge, parry, counter, and use supernatural powers.  
> The environment becomes part of the battle.  
> The last surviving warrior stands victorious.

The project must achieve this experience while respecting the strict constraints:

**8 GB RAM**

**M1 laptop**

**20 GB maximum project storage**

**~40 FPS minimum development target**

**Scalable quality from optimized 1080p to high-quality 4K output**

**Photorealistic medieval fantasy presentation**

**2–5 player multiplayer**

**Modular architecture**

**Blender-based asset production**

**Antigravity-assisted development**

The result should be a technically clean foundation that can grow into a much larger medieval multiplayer game without requiring the core systems to be rebuilt.