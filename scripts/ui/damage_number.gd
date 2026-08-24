class_name DamageNumber
extends Label3D

## DamageNumber — Floating billboarded 3D combat text displaying damage numbers and combat cues.

static func spawn(parent: Node, global_pos: Vector3, text_content: String, color: Color = Color.WHITE, is_large: bool = false) -> DamageNumber:
	if not parent: return null

	var dmg_lbl: DamageNumber = DamageNumber.new()
	dmg_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	dmg_lbl.no_depth_test = true
	dmg_lbl.text = text_content
	dmg_lbl.modulate = color
	dmg_lbl.outline_modulate = Color.BLACK
	dmg_lbl.outline_size = 8
	dmg_lbl.font_size = 48 if is_large else 36
	dmg_lbl.top_level = true
	parent.add_child(dmg_lbl)
	dmg_lbl.global_position = global_pos + Vector3(randf() * 0.4 - 0.2, randf() * 0.3, randf() * 0.4 - 0.2)

	var tween: Tween = dmg_lbl.create_tween().set_parallel(true)
	var target_y: float = dmg_lbl.global_position.y + (1.2 if is_large else 0.8)
	tween.tween_property(dmg_lbl, "global_position:y", target_y, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(dmg_lbl, "modulate:a", 0.0, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(dmg_lbl.queue_free)

	return dmg_lbl
