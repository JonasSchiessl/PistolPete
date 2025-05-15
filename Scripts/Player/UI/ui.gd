extends CanvasLayer

@onready var health_bg = $Health/background
@onready var health_bar = $Health/HealthBar
@onready var ammo_label = $Ammo/AmmoLabel
@onready var reload_indicator = $Ammo/ReloadIndicator

var max_health = 10
var current_health = 10

func _ready():
	print("UI max_health: ", max_health, " current_health: ", current_health)
	# Set initial position and size
	$Health.position = Vector2(16, 16)
	update_health(max_health)
	
	# Find the player and connect health signals
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Connect to health component
		if player.has_node("HealthComponent"):
			var health_component = player.get_node("HealthComponent")
			health_component.health_changed.connect(_on_player_health_changed)
			# Get initial health values
			max_health = health_component.maxHealth
			current_health = health_component.health
			update_health(current_health)
		
		# Connect ammo signals
		player.ammo_changed.connect(_on_ammo_changed)
		player.reload_started.connect(_on_reload_started)
		player.reload_progress.connect(_on_reload_progress)
		player.reload_finished.connect(_on_reload_finished)
		
		# Hide reload indicator initially
		if reload_indicator:
			reload_indicator.visible = false

func _on_player_health_changed(new_health):
	update_health(new_health)

func update_health(value):
	current_health = value
	# Update the health bar fill
	var health_percent = float(current_health) / float(max_health)
	# Get the background width for proper scaling
	var bar_width = health_bg.size.x - 8  
	
	# Set the bar width
	health_bar.size.x = bar_width * health_percent

# New ammo UI functions
func _on_ammo_changed(current, maximum):
	if ammo_label:
		ammo_label.text = str(current) + " / " + str(maximum)
		
		# Change color based on ammo status
		if current == 0:
			ammo_label.add_theme_color_override("font_color", Color(1, 0, 0)) # Red
		elif current <= maximum * 0.3:
			ammo_label.add_theme_color_override("font_color", Color(1, 0.5, 0)) # Orange
		else:
			ammo_label.add_theme_color_override("font_color", Color(1, 1, 1)) # White

func _on_reload_started(reload_time):
	if reload_indicator:
		reload_indicator.visible = true
		reload_indicator.value = 0

func _on_reload_progress(progress):
	if reload_indicator:
		reload_indicator.value = progress

func _on_reload_finished():
	if reload_indicator:
		reload_indicator.visible = false
	
