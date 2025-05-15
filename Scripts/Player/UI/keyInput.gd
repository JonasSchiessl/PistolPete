extends Control

@export var KeyText = "Text"

func _ready():
	$Panel/RichTextLabel.text = KeyText
	$Timer.start()

func _on_timer_timeout() -> void:
	$Panel/RichTextLabel.visible = !$Panel/RichTextLabel.visible
