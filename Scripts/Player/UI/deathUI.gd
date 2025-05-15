extends Control

signal restart_game
signal return_to_menu

@onready var deathAudio = $DeathSFX

func _ready():
	# Hide initially
	visible = false

func show_death_screen():
	visible = true
	deathAudio.play()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_menu_pressed() -> void:
	get_tree().paused = false
	emit_signal("return_to_menu")


func _on_restart_pressed() -> void:
	get_tree().paused = false
	emit_signal("restart_game")
