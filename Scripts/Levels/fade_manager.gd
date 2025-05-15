extends CanvasLayer

var screen_fade_scene := preload("res://Scenes/Level/Components/screen_fade.tscn")
var screen_fade: Control
var animation_player: AnimationPlayer

func _ready():
	screen_fade = screen_fade_scene.instantiate()
	add_child(screen_fade)
	var color_rect := screen_fade.get_node("ColorRect")
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	animation_player = screen_fade.get_node("AnimationPlayer")
	print(screen_fade.get_children())


func fade_out():
	animation_player.play("FadeIn")
	await animation_player.animation_finished

func fade_in():
	animation_player.play("FadeOut")
	await animation_player.animation_finished

func fade_and_change_scene(new_scene_path: String) -> void:
	await fade_out()
	get_tree().change_scene_to_file(new_scene_path)
