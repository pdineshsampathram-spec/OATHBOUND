class_name CharacterData
extends Resource

## Data-driven character configuration resource for OATHBOUND.
## Defines base attributes, combat stats, stamina rates, and timing.

@export_group("Character Info")
@export var character_name: String = "Knight"
@export var character_description: String = "Balanced warrior with longsword and shield."

@export_group("Health & Poise")
@export var max_health: float = 100.0
@export var poise: float = 50.0

@export_group("Stamina")
@export var max_stamina: float = 100.0
@export var stamina_regen_rate: float = 25.0 # Per second
@export var stamina_regen_delay: float = 0.8 # Delay after spending stamina before regen starts
@export var sprint_stamina_drain: float = 18.0 # Per second
@export var dodge_stamina_cost: float = 20.0 # Instant cost
@export var attack_stamina_cost: float = 14.0 # Instant cost
@export var block_stamina_drain_per_hit: float = 15.0 # Per hit absorbed

@export_group("Movement")
@export var move_speed: float = 5.5
@export var sprint_speed: float = 8.5
@export var acceleration: float = 12.0
@export var deceleration: float = 14.0
@export var rotation_speed: float = 12.0

@export_group("Combat - Light Attack")
@export var attack_damage: float = 18.0
@export var attack_duration: float = 0.55 # Total state duration in seconds
@export var attack_hitbox_start: float = 0.15 # When hitbox becomes active
@export var attack_hitbox_end: float = 0.35 # When hitbox deactivates
@export var attack_forward_impulse: float = 2.5 # Slight step forward during swing

@export_group("Combat - Defense & Dodge")
@export var block_damage_reduction: float = 0.75 # 75% reduction when blocking
@export var block_move_speed_multiplier: float = 0.45 # Slower movement while guarding
@export var dodge_speed: float = 11.0
@export var dodge_duration: float = 0.4
@export var dodge_iframe_start: float = 0.05
@export var dodge_iframe_end: float = 0.28
