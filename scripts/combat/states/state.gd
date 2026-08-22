class_name State
extends Node

## Abstract base State class for OATHBOUND StateMachine architecture.

var state_machine: Node = null
var character = null

func enter(_msg: Dictionary = {}) -> void:
	pass

func exit() -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass

func process_state(_delta: float) -> void:
	pass

func physics_process_state(_delta: float) -> void:
	pass

func transition_to(target_state_name: String, msg: Dictionary = {}) -> void:
	if state_machine and state_machine.has_method("transition_to"):
		state_machine.transition_to(target_state_name, msg)
