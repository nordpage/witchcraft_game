extends Node2D

var lever_value: float = 0.0
@export var increment: float = 0.1
const MIN_VALUE = -1.0
const MAX_VALUE = 1.0

signal lever_changed(value)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			lever_value = clamp(lever_value + increment, MIN_VALUE, MAX_VALUE)
			emit_signal("lever_changed", lever_value)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			lever_value = clamp(lever_value - increment, MIN_VALUE, MAX_VALUE)
			emit_signal("lever_changed", lever_value)
