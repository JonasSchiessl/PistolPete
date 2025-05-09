extends Node
class_name GameManager

var death_ui_scene = preload("res://Scenes/Player/deathUI.tscn")
var death_ui
var canvas_layer

func _ready():
	print("GameManager initialized")
	
	var spawner = preload("res://Scenes/Level/enemy_spawner.tscn").instantiate()
	add_child(spawner)
	
	var health_ui = preload("res://Scenes/Player/UI.tscn").instantiate()
	add_child(health_ui)
	
	# Create a CanvasLayer for UI elements
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10  
	add_child(canvas_layer)
	
	# Instance the UI and add it to the CanvasLayer instead
	death_ui = death_ui_scene.instantiate()
	canvas_layer.add_child(death_ui)
	death_ui.visible = false
	
	# Connect UI signals
	death_ui.restart_game.connect(_on_restart_game)
	death_ui.return_to_menu.connect(_on_return_to_menu)
	
	# Connect to all health components in the scene
	call_deferred("connect_health_components") 

func connect_health_components():
	# Find all HealthComponent nodes
	var health_components = get_tree().get_nodes_in_group("health_component")
	print("Found", health_components.size(), "health components")
	
	for component in health_components:
		print("Connecting to health component:", component)
		if !component.is_connected("entity_died", Callable(self, "_on_entity_died")):
			component.entity_died.connect(_on_entity_died)

func _on_entity_died(entity):
	print("Entity died signal received, entity:", entity)
	
	# Check if the entity that died is the player
	if entity.is_in_group("player"):
		death_ui.show_death_screen()
		
		# Disable player input
		entity.disable_input()
		get_tree().paused = true
		
		# Make death UI process when paused
		death_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	else:
		entity.queue_free()

func _on_restart_game():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Level/world.tscn")

func _on_return_to_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Level/main_menu.tscn")
