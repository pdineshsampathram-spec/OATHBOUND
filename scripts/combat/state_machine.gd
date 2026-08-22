class_name StateMachine
extends Node

## Reusable finite state machine managing combat and movement states.
## Executes physics and process logic on the server/authority.

signal state_changed(previous_state: String, current_state: String)

@export var initial_state: State = null

var current_state: State = null
var states: Dictionary = {}
var character: CharacterBody3D = null

func _ready() -> void:
	var parent_node: Node = get_parent()
	if parent_node is CharacterBody3D:
		character = parent_node

	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			states[child.name] = child
			child.state_machine = self
			child.character = character

	await parent_node.ready
	if initial_state:
		transition_to(initial_state.name)
	elif get_child_count() > 0 and get_child(0) is State:
		transition_to(get_child(0).name)

func _unhandled_input(event: InputEvent) -> void:
	if _is_authority() and current_state:
		current_state.handle_input(event)

func _process(delta: float) -> void:
	if _is_authority() and current_state:
		current_state.process_state(delta)

func _physics_process(delta: float) -> void:
	if _is_authority() and current_state:
		current_state.physics_process_state(delta)

func _is_authority() -> void:
	if not multiplayer.has_multiplayer_peer():
		return true
	return multiplayer.is_server()

func transition_to(target_state_name: String, msg: Dictionary = {}) -> void:
	var target_key: String = target_state_name.to_lower()
	if not states.has(target_key):
		push_warning("StateMachine: Attempted transition to non-existent state '%s'" % target_state_name)
		return

	var target_state: State = states[target_key]
	if target_state == current_state and msg.is_empty():
		return

	var prev_name: String = current_state.name if current_state else "None"
	if current_state:
		current_state.exit()

	current_state = target_state
	current_state.enter(msg)
	state_changed.emit(prev_name, current_state.name)

func get_current_state_name() -> String:
	return current_state.name if current_state else "None"
