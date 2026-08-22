class_name CharacterData
extends Resource

## Data-driven character configuration resource for OATHBOUND.
## Defines base attributes, combat stats, stamina rates, poise, supernatural abilities, and visual style.

enum WeaponStyle { SWORD_SHIELD, GREAT_AXE, DUAL_BLADES }

@export_group("Character Identity")
@export var character_name: String = "Knight"
@export var character_title: String = "The Sentinel"
@export var character_description: String = "Balanced warrior with longsword and shield. High defense and deadly parries."
@export var weapon_style: WeaponStyle = WeaponStyle.SWORD_SHIELD
@export var primary_color: Color = Color(0.22, 0.26, 0.32, 1.0)
@export var accent_color: Color = Color(0.18, 0.35, 0.55, 1.0)

@export_group("Health & Poise")
@export var max_health: float = 120.0
@export var max_poise: float = 65.0
@export var poise_regen_rate: float = 15.0
@export var poise_regen_delay: float = 1.5

@export_group("Stamina")
@export var max_stamina: float = 100.0
@export var stamina_regen_rate: float = 25.0
@export var stamina_regen_delay: float = 0.8
@export var sprint_stamina_drain: float = 18.0
@export var dodge_stamina_cost: float = 20.0
@export var attack_stamina_cost: float = 14.0

@export_group("Supernatural Energy")
@export var max_energy: float = 100.0
@export var energy_regen_rate: float = 15.0

@export_group("Movement")
@export var move_speed: float = 5.2
@export var sprint_speed: float = 8.0
@export var acceleration: float = 12.0
@export var deceleration: float = 14.0
@export var rotation_speed: float = 12.0

@export_group("Combat - Light Attack")
@export var attack_damage: float = 18.0
@export var attack_duration: float = 0.55
@export var attack_hitbox_start: float = 0.15
@export var attack_hitbox_end: float = 0.35
@export var attack_forward_impulse: float = 2.5
@export var light_attack_poise_damage: float = 12.0

@export_group("Combat - Heavy Attack")
@export var heavy_attack_damage: float = 32.0
@export var heavy_attack_stamina_cost: float = 25.0
@export var heavy_attack_duration: float = 0.85
@export var heavy_attack_hitbox_start: float = 0.3
@export var heavy_attack_hitbox_end: float = 0.55
@export var heavy_attack_forward_impulse: float = 1.5
@export var heavy_attack_poise_damage: float = 35.0

@export_group("Combat - Charged Attack")
@export var charged_attack_min_charge: float = 0.4
@export var charged_attack_max_charge: float = 1.2
@export var charged_attack_damage_min: float = 28.0
@export var charged_attack_damage_max: float = 55.0
@export var charged_attack_stamina_cost: float = 30.0
@export var charged_attack_poise_damage_max: float = 60.0
@export var charged_attack_knockdown_threshold: float = 0.8

@export_group("Combat - Defense & Parry")
@export var block_damage_reduction: float = 0.80
@export var block_stamina_drain_per_hit: float = 12.0
@export var block_move_speed_multiplier: float = 0.45
@export var parry_window: float = 0.20
@export var parry_stun_duration: float = 0.7
@export var parry_counter_window: float = 0.9
@export var parry_stamina_cost: float = 8.0

@export_group("Combat - Dodge")
@export var dodge_speed: float = 10.5
@export var dodge_duration: float = 0.4
@export var dodge_iframe_start: float = 0.05
@export var dodge_iframe_end: float = 0.28

@export_group("Combat - Crowd Control & Finisher")
@export var stagger_duration: float = 1.0
@export var stun_duration: float = 0.7
@export var knockdown_duration: float = 1.5
@export var knockdown_recovery: float = 0.6
@export var finisher_damage: float = 85.0
@export var finisher_duration: float = 1.3
@export var finisher_range: float = 2.5
@export var finisher_health_threshold: float = 0.25

@export_group("Supernatural Abilities (4 Slots)")
@export var abilities: Array[AbilityData] = []
