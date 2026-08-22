# OATHBOUND — Antigravity Build Guide (Godot 4 + Blender)

Target stack: **Godot 4.4+ (Forward+ renderer, GDScript)** for the game, **Blender** for
assets, **Antigravity IDE** driving both. Hardware: M1 MacBook Air, 8GB RAM, 20GB hard
storage cap for this project, 40 FPS minimum dev target.

Work through this top to bottom. Each "PROMPT" block is meant to be pasted directly into
an Antigravity agent conversation.

---

## Before Step 0: the one caveat that matters most for your laptop

Your original doc's Section 27 maps five specialist roles (Combat, Multiplayer, Ability,
Art Pipeline, QA/Performance) onto Antigravity's Manager view, which really does let you
spawn up to five parallel agents in separate workspaces. Don't do that literally on this
machine yet. Each agent that runs the game, exports a build, or drives Blender's CLI is a
separate heavy process — five of those at once on 8GB RAM is the fastest way to actually
cook the laptop, faster than the finished game ever will.

**Practical rule:** treat the five roles as five *hats*, worn one at a time, in separate
conversations, sequentially. Parallel agents are fine only for tasks that stay pure
text/code with no process spawned — e.g. one agent writing ability data resources while
another writes documentation. Anything that opens the game, Blender, or an export never
runs in parallel with another such task.

---

## Step 0 — One-time project setup

**PROMPT — Project scaffold:**

> Set up a new Godot 4.4+ project called OATHBOUND using the Forward+ renderer. In
> Project Settings: cap `Engine.max_fps` at 60, enable V-Sync, leave physics at 60 ticks/
> second — never propose uncapping the frame rate "to test max performance," since
> sustained uncapped GPU load is what drives thermal throttling on this machine. Create
> this folder structure: `/scenes`, `/scripts`, `/resources/characters`,
> `/resources/abilities`, `/assets/environment`, `/assets/characters`, `/assets/audio`,
> `/docs`. Initialize git with a `.gitignore` covering `.godot/`, export artifacts, and
> Blender `.blend1`/`.blend2` backup files. Do not write any gameplay code yet.

**Then create the persistent rules file.** Antigravity auto-loads a root-level
`AGENTS.md` into every agent session in the workspace, so paste this once and you never
have to repeat these constraints again:

**PROMPT — Create AGENTS.md:**

> Create a file named `AGENTS.md` at the project root with exactly this content:
>
> ```markdown
> # OATHBOUND — Project Rules
>
> ## Hardware & hard limits
> - Dev machine: MacBook Air M1, 8GB unified RAM, 20GB hard storage cap for this project.
> - Performance floor: 40 FPS minimum at "Low" quality on this machine. A regression
>   below that is a bug, not an acceptable trade-off.
> - Engine.max_fps stays capped at 60 with V-Sync on, always.
>
> ## Engine & tooling
> - Godot 4.4+, Forward+ renderer (switch to Mobile renderer if profiling shows Forward+
>   is the bottleneck).
> - GDScript by default. Only propose C# for a system that genuinely needs it, and name
>   the .NET runtime overhead when you do.
> - Assets come from Blender as glTF 2.0 (.glb). Never ask for FBX round-trips.
>
> ## Architecture rules
> - Server-authoritative multiplayer only. Clients never decide their own damage, hits,
>   or deaths.
> - Combat is a state machine (see /docs/combat-states.md), not one monolithic
>   player-controller script.
> - Characters, weapons, and abilities are data-driven (Resource files), not hardcoded
>   per-character branches.
> - Ship small, independently testable changes. Don't bundle unrelated systems into one
>   task.
>
> ## Performance & thermal discipline
> - Any task adding visual complexity (particles, lights, post-processing, materials)
>   reports draw calls, triangle count, and FPS before/after using the in-engine debug
>   overlay.
> - Never run more than one Godot instance, one Blender instance, and one process-
>   spawning agent task at the same time. If a task needs multiple game instances
>   (multiplayer testing), say so and get confirmation before launching them.
> - Flag any texture import over 2K resolution unless it's an explicitly designated hero
>   asset.
> - Report current total project folder size after any asset import.
>
> ## Documentation
> - Log non-trivial architecture decisions to /docs/decisions.md, dated.
> - Keep /docs/storage-budget.md updated against this target allocation:
>   Source/project 2-3GB, Environment 4-5GB, Characters/animations 3-4GB,
>   Textures/materials 3-4GB, Audio/VFX 1-2GB, Cache/build 3-4GB, Safety margin ~2GB.
> ```

---

## Step 1 — Performance monitoring harness (build before any gameplay)

**PROMPT — In-engine overlay:**

> Before writing any gameplay code, build a debug performance overlay: a CanvasLayer
> scene toggled with F3 showing FPS, frame time in milliseconds, draw calls, video
> memory, and object count, using Godot's `Performance` singleton. This overlay must be
> present in every build from now on — don't let it get dropped in later scenes.

**PROMPT — Repeatable perf-check workflow:**

> Create `.agent/workflows/perf-check.md` with this content, so I can invoke it later as
> `/perf-check`:
>
> ```markdown
> ---
> description: Run a full performance and storage audit before and after major changes
> ---
> ## Steps
> ### 1. Capture engine metrics
> - Run the project for at least 30 seconds of typical combat (attack, block, dodge,
>   ability use).
> - Report average FPS, minimum FPS, frame time (ms), draw calls, and video memory.
>
> ### 2. Capture storage
> - Run `du -sh` on the project root and each top-level asset folder.
> - Compare against the AGENTS.md budget and flag anything over.
>
> ### 3. Flag regressions
> - Compare against the last entry in /docs/perf-log.md. If FPS dropped more than 10% or
>   any storage category grew more than 500MB in one task, stop and report before
>   continuing.
>
> ### 4. Append results
> - Add a new dated row to /docs/perf-log.md.
> ```

**On your machine, not through the agent** — keep a terminal or menu-bar tool open while
testing so you can see thermal state directly:
- `pmset -g therm` shows whether macOS is currently throttling the CPU.
- `sudo powermetrics --samplers smc -i 1000 -n 1` gives a power/thermal-pressure snapshot.
- Activity Monitor's Energy/Memory tabs work fine too if you'd rather not use the
  terminal — a free menu-bar app like TG Pro is the easiest way to watch temperature
  continuously on Apple Silicon.

---

## Phase 1 — Vertical slice (single player, blockout arena)

**PROMPT:**

> Build the vertical slice: a CharacterBody3D player controller in a blockout arena
> (simple boxes, ~40×40m, no art yet). Include WASD movement + sprint, a third-person
> camera with basic collision, one sword with a light attack, blocking, a short evasive
> dodge with a brief invulnerability window, a Health resource, a Stamina resource that
> drains on sprint/dodge/block and regenerates when idle, and death at 0 health. Local
> single-player only, no networking yet. Wire up the F3 overlay we already built and run
> `/perf-check` when done.

---

## Phase 2 — Multiplayer (2 players, then scale)

**PROMPT — 2-player networking:**

> Add server-authoritative multiplayer using Godot's high-level multiplayer API
> (ENetMultiplayerPeer + MultiplayerSynchronizer/MultiplayerSpawner). The server owns
> health, stamina, damage calculation, hit validation, and death; clients only send input
> and locally predict movement for responsiveness. Get exactly 2 players fighting in the
> existing blockout arena. Before launching two debug instances to test host+client on
> this one machine, confirm with me — running two instances roughly doubles RAM/GPU load.
> Run `/perf-check` with both instances running.

**PROMPT — Scale to 5:**

> Extend the existing 2-player multiplayer to support 3, then 4, then 5 players, without
> changing the underlying networking architecture — only extend spawn points and lobby
> capacity. Test each player-count increment separately with `/perf-check` after each
> one. If FPS drops below 40 at any point, stop there and report instead of continuing to
> the next player count.

---

## Phase 3 — Combat depth

**PROMPT:**

> Implement the full combat state machine (Idle, Movement, Sprint, LightAttack,
> HeavyAttack, ChargedAttack, Block, Parry, Dodge, Ability, Stunned, Staggered,
> KnockedDown, Finisher, Dead) as a clean state pattern — a StateMachine node with per-
> state logic, not one large branching script. Add heavy attacks, charged attacks, a
> precisely-timed parry with a counterattack window, stagger from heavy hits, knockdown
> from especially strong hits, and a finisher usable only against a staggered or
> critically-low-health opponent. Keep all of it server-authoritative. Document the
> state machine in /docs/combat-states.md as you go.

---

## Phase 4 — The three fighters

**PROMPT:**

> Create the three fighters as data-driven CharacterData resources, all reusing the same
> BaseCharacter scene and combat state machine — differences come entirely from data
> (health, stamina, speed, armor, weapon stats, animation set) and swappable weapon
> components, never duplicated per-character logic:
> - **Knight**: longsword + shield, high defense/parry, slower movement.
> - **Berserker**: great axe, heavy stagger/armor-break damage, slower attacks, weaker
>   defense.
> - **Shadow Warrior**: dual blades, fast mobility/combo potential, lower durability.
>
> Use placeholder capsule/box meshes — don't wait on final Blender art for this.

---

## Phase 5 — Ability framework

**PROMPT:**

> Build a reusable AbilityBase framework as Resource-based data (damage, cooldown,
> resource cost, range, area, cast time, animation name, VFX/SFX references, status
> effects), with behavior variants for Offensive, Defensive, Mobility, Control, and
> Ultimate abilities. Implement each fighter's 3 abilities + 1 ultimate (Knight: Holy
> Guard / Judgement Strike / Shield Rush / Divine Execution; Berserker: Blood Rage /
> Ground Breaker / Axe Throw / Wrath; Shadow Warrior: Shadow Step / Smoke Veil / Blade
> Storm / Death From Shadow) using placeholder VFX — simple particle bursts or colored
> shapes are fine for now. Validate cooldowns and costs server-side.

---

## Phase 6 — Blender art pipeline

This phase happens mostly in Blender itself, not Antigravity. Follow your doc's own
sequence: blockout → structural assets → hero assets → surface detail → vegetation
instancing. Antigravity's useful role here is automation and validation, not modeling:

**PROMPT:**

> Write an import-validation tool that checks every `.glb` dropped into
> `/assets/environment` or `/assets/characters`: flag any texture over 2K outside a
> designated `/hero_assets` folder, flag any single mesh whose triangle count looks too
> high for its intended LOD tier, and report the current total size of each asset folder
> against the AGENTS.md budget. Also scaffold LOD0–LOD3 import presets in Godot's import
> settings for one sample environment prop, so the Blender pipeline has a consistent
> target to export into.

Keep Blender closed while the Godot editor is actively running gameplay tests, and vice
versa — running both with heavy scenes loaded at once is one of the easiest ways to hit
memory pressure on 8GB.

---

## Phase 7 — Optimization pass

**PROMPT:**

> Run a full optimization pass on the current vertical slice: profile with the F3
> overlay and Godot's Debugger > Monitors across all player counts (2 through 5),
> identify the top 3 actual performance costs (draw calls, shader complexity, script
> overhead, physics, or network traffic), and fix only those — no speculative
> optimization elsewhere. Run `/perf-check` after each fix and report before/after
> numbers. Confirm the project is still under the 20GB total and within each category's
> budget in AGENTS.md.

---

## Phase 8 — Polish

**PROMPT:**

> Add UI (health/stamina bars, ability cooldown indicators, match timer, results
> screen), SFX hooks for attacks/blocks/parries/deaths, the full match flow (main menu →
> lobby → character select → arena → results), and camera polish (hit-feedback shake,
> finisher camera). Run `/perf-check` before merging any of this in — polish is the
> phase most likely to quietly creep past your performance and storage budgets.

---

## Using the five "engineer" roles without overloading the laptop

When you do want to work on more than one system, open separate Antigravity
conversations for Combat, Multiplayer, Ability, Art Pipeline, and QA/Performance — but
run them **one at a time** whenever the task launches a process (the game, an export, a
Blender operation). Save actual parallel Manager-view agents for pure code/doc work,
like one agent drafting ability data resources while another writes `/docs` content —
never two agents both trying to run the game at once.
