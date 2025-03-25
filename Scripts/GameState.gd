# GameState.gd
extends Node

enum Mode {
	DRIVING,
	WALKING
}

var current_mode: Mode = Mode.DRIVING
