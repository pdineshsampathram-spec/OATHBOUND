class_name AbilityData
extends Resource

## Data-driven Supernatural Ability specification for OATHBOUND.
## Defines combat behavior, cooldowns, resource costs, scaling, and visual feedback.

enum Category { OFFENSIVE, DEFENSIVE, MOBILITY, CONTROL, ULTIMATE }
enum ExecutionType {
	DIRECT_STRIKE,
	DASH_STRIKE,
	RADIAL_AOE,
	TELEPORT_STRIKE,
	BUFF_SELF,
	PROJECTILE,
	MULTI_HIT_COMBO,
	MULTI_TARGET_TELEPORT,
	RADIAL_PULSE_CHAIN
}

@export_group("Identity")
@export var ability_name: String = "Ability"
@export var description: String = "Description of the ability."
@export var category: Category = Category.OFFENSIVE
@export var execution_type: ExecutionType = ExecutionType.DIRECT_STRIKE

@export_group("Costs & Timing")
@export var energy_cost: float = 25.0
@export var stamina_cost: float = 10.0
@export var cooldown: float = 8.0
@export var cast_time: float = 0.5
@export var duration: float = 0.0 # For buffs / continuous effects

@export_group("Combat Impact")
@export var damage: float = 30.0
@export var poise_damage: float = 35.0
@export var range_distance: float = 6.0
@export var aoe_radius: float = 3.0
@export var hit_count: int = 1 # For multi-hit combos
@export var buff_multiplier: float = 1.0 # E.g. +40% damage (1.4) or 50% defense (0.5 damage taken)
@export var projectile_speed: float = 20.0

@export_group("Visual Feedback")
@export var vfx_color: Color = Color(0.9, 0.6, 0.2, 1.0)
@export var animation_trigger: String = "ability_cast"
