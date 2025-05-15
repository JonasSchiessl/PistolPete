extends Control

func _ready() -> void:
	$Credits.visible = false
	self.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_start_pressed() -> void:
	await FadeManager.fade_and_change_scene("res://Scenes/Level/Level1/intro.tscn")

func _on_credits_pressed() -> void:
	$Credits.visible = true


func _on_exit_pressed() -> void:
	$Credits.visible = false
