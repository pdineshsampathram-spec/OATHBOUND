# OATHBOUND — Master Quality Target & Visual Vision

## 1. Project Goal
Transform OATHBOUND into a believable, realistic medieval supernatural arena fighter with weighty, responsive, readable, and skill-based melee combat inside a detailed and atmospheric ruined medieval fortress courtyard.

**Target Rating:** 8/10+ Visual Presentation & Combat Feel.

---

## 2. Hardware & Performance Constraints
- **Hardware Target**: MacBook Air M1, 8GB Unified RAM.
- **Storage Budget**: 20 GB hard project limit (Current usage ~5.2 MB, <0.03% of cap).
- **Runtime Performance Floor**: 40 FPS minimum under representative combat load; 60 FPS cap with V-Sync.
- **Physics**: 60 ticks/second, server-authoritative simulation.

---

## 3. Human-Quality Checklist & Quality Gates

### A. Environment Gate
- Look at the scene from the default gameplay third-person camera:
  - Does it look like an authentic, ruined 15th-century medieval fortress?
  - Does the masonry have visible mortar joints, edge damage, and surface weathering rather than flat toy-like surfaces?
  - Is the ground varied with cobblestone, flagstones, dirt crevices, and puddles?
  - Does the lighting create depth, rich shadows, and atmospheric perspective?

### B. Character & Weapon Gate
- Does the Knight look like a real armored warrior with authentic anatomical proportions?
- Are the armor plates (cuirass, pauldrons, gauntlets, sallet helmet) visibly articulated with chainmail undergarments, leather straps, and brass buckles?
- Is there clear PBR material separation between polished steel, dark oxidized iron, brass, leather, and cloth?
- Does the Oakeshott longsword have an authentic blade fuller, crossguard, and wire/leather-wrapped grip?

### C. Combat Feel Gate
- **Attack Lifecycle**: Does every strike have clear preparation (anticipation), acceleration, contact, follow-through, and recovery?
- **Weight & Feedback**: Do heavy attacks feel heavy through hitstop (0.05s client presentation micro-freeze), camera trauma shake, incandescent sparks, and deep resonant audio?
- **Skill Mechanics**: Does parrying require tight timing and reward the player with a distinct visual/audio cue and counter opening?
- **Hit Reactions**: Does the opponent react according to attack magnitude (light flinch, heavy pushback, poise-broken stagger, knockdown)?

---

## 4. Single Source of Truth Benchmark
All visual and combat quality assessments must be conducted inside:
`scenes/debug/quality_benchmark_arena.tscn`
