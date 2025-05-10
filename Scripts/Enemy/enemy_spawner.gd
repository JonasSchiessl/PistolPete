extends Node2D
class_name EnemySpawner

# Enemy scene to spawn
@export var enemy_scene: PackedScene
@export var spawn_interval: float = 3.0
@export var initial_count: int = 1
@export var max_enemies: int = 15
@export var max_per_wave: int = 5
@export var difficulty_scaling: float = 0.8
@export var enemy_scale: float = 2

# Tracking variables
var current_enemies: int = 0
var spawn_timer: float = 0.0
var current_wave: int = 0
var active_enemies = {} 
var wave_in_progress: bool = false

# UI variables
var wave_label: Label
var count_label: Label 
var canvas_layer: CanvasLayer

# Font resource
@export var custom_font_path: String = "res://Assets/UI/fonts/Ancient Modern Tales.otf"
var custom_font: FontFile

# Spawn points array
var spawn_points: Array = []

func _ready():
	load_custom_font()
	setup_wave_ui()
	
	# Find all spawners in the world
	call_deferred("collect_spawn_points")
	
	# Find all existing enemies in the scene
	call_deferred("track_existing_enemies")

func collect_spawn_points():
	# Get all nodes in the "enemy_spawn_points" group
	spawn_points = get_tree().get_nodes_in_group("enemy_spawn_points")
	print("Found", spawn_points.size(), "enemy spawn points")
	
	if spawn_points.size() == 0:
		push_warning("No enemy spawn points found in the scene. Add some to your world!")

func track_existing_enemies():
	# Wait one frame for the scene to fully load
	await get_tree().process_frame
	
	# Find all enemies in the scene
	var existing_enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in existing_enemies:
		# Only add if not already tracked
		var id = enemy.get_instance_id()
		if !active_enemies.has(id):
			# Add to tracking
			active_enemies[id] = enemy
			
			# Connect its health component
			if enemy.has_node("HealthComponent"):
				var health_comp = enemy.get_node("HealthComponent")
				var callable = Callable(self, "_on_enemy_died").bind(enemy)
				
				# Disconnect any existing connections first to avoid duplicates
				if health_comp.is_connected("entity_died", callable):
					health_comp.disconnect("entity_died", callable)
				
				# Connect the signal
				health_comp.entity_died.connect(callable)
	
	# Update count
	current_enemies = active_enemies.size()
	print("Total tracked enemies: ", current_enemies)

func _process(delta):
	# Only count down timer if no wave is in progress
	if !wave_in_progress:
		# Update spawn timer
		spawn_timer += delta
		
		# If it's time to spawn a new wave
		if spawn_timer >= spawn_interval:
			spawn_wave()
			spawn_timer = 0.0
	
	# Clean up invalid references
	clean_up_enemies()
	
	# Check if wave is complete (all enemies dead)
	if wave_in_progress and current_enemies == 0:
		wave_in_progress = false
		wave_complete()
	
	# Update the enemy count display
	update_enemy_count()

func clean_up_enemies():
	# Remove invalid references from dictionary
	var to_remove = []
	
	for id in active_enemies:
		var enemy = active_enemies[id]
		if !is_instance_valid(enemy):
			to_remove.append(id)
	
	for id in to_remove:
		active_enemies.erase(id)
	
	# Update count based on dictionary size
	current_enemies = active_enemies.size()

func spawn_wave():
	current_wave += 1
	wave_in_progress = true
	
	# Display wave notification
	display_wave_notification("Wave " + str(current_wave))
	
	# Calculate enemies to spawn
	var enemies_to_spawn = initial_count + floor(current_wave * difficulty_scaling)
	enemies_to_spawn = min(enemies_to_spawn, max_per_wave)
	
	# Get valid spawn points separated by direction
	var spawn_points_dict = filter_offscreen_spawn_points()
	var left_points = spawn_points_dict["left"]
	var right_points = spawn_points_dict["right"]
	
	# Prepare array of valid spawn positions
	var spawn_positions = []
	
	# Add closest left point if available
	if left_points.size() > 0:
		spawn_positions.append(left_points[0].global_position)
		print("Using left spawn at: ", left_points[0].global_position)
	
	# Add closest right point if available
	if right_points.size() > 0:
		spawn_positions.append(right_points[0].global_position)
		print("Using right spawn at: ", right_points[0].global_position)
	
	# If no positions at all, we can't spawn
	if spawn_positions.size() == 0:
		push_warning("No valid spawn positions found!")
		return
	
	# Spawn enemies, randomly choosing between available positions
	for i in range(enemies_to_spawn):
		if current_enemies >= max_enemies:
			break
		
		# Choose a random spawn position from our options
		var spawn_pos = spawn_positions[randi() % spawn_positions.size()]
		
		# Add a small random offset to prevent stacking
		var offset = Vector2(
			randf_range(-30, 30),
			randf_range(-10, 10)
		)
		
		# Spawn the enemy
		spawn_enemy(spawn_pos + offset)
	
	print("Wave " + str(current_wave) + " - Spawned " + str(enemies_to_spawn) + " enemies")

func filter_offscreen_spawn_points() -> Dictionary:
	var left_points = []
	var right_points = []
	var camera = get_viewport().get_camera_2d()
	var player = get_tree().get_first_node_in_group("player")
	
	if !camera or !player:
		return {"left": spawn_points, "right": []}
	
	# Get camera rect in world space
	var viewport_rect = get_viewport().get_visible_rect()
	var camera_rect = Rect2(
		camera.global_position - viewport_rect.size/2,
		viewport_rect.size
	)
	
	# Add margin
	camera_rect = camera_rect.grow(200)
	
	# Find all off-screen points and separate by left/right
	for point in spawn_points:
		if !camera_rect.has_point(point.global_position) and point.active:
			# Determine if point is to left or right of player
			if point.global_position.x < player.global_position.x:
				left_points.append(point)
			else:
				right_points.append(point)
	
	# Sort by distance to player (closest first)
	left_points.sort_custom(func(a, b): 
		return a.global_position.distance_to(player.global_position) < b.global_position.distance_to(player.global_position)
	)
	
	right_points.sort_custom(func(a, b): 
		return a.global_position.distance_to(player.global_position) < b.global_position.distance_to(player.global_position)
	)
	
	# If either side is empty, add fallbacks
	if left_points.size() == 0 and right_points.size() == 0:
		print("WARNING: No off-screen spawn points found!")
		
		# Use any active points as fallback
		for point in spawn_points:
			if point.active:
				if point.global_position.x < player.global_position.x:
					left_points.append(point)
				else:
					right_points.append(point)
					
		# Sort fallbacks
		left_points.sort_custom(func(a, b): 
			return a.global_position.distance_to(player.global_position) < b.global_position.distance_to(player.global_position)
		)
		
		right_points.sort_custom(func(a, b): 
			return a.global_position.distance_to(player.global_position) < b.global_position.distance_to(player.global_position)
		)
	
	return {"left": left_points, "right": right_points}

func spawn_enemy(pos: Vector2):
	var enemy = enemy_scene.instantiate()
	
	# Set scale if property exists
	if "enemy_scale" in enemy:
		enemy.enemy_scale = enemy_scale
	
	# Add to scene
	get_parent().add_child(enemy)
	enemy.global_position = pos
	
	# Make sure it's in the enemies group
	if !enemy.is_in_group("enemies"):
		enemy.add_to_group("enemies")
	
	# Set collision layer to Layer 3 (2^2=4 in binary)
	if enemy is CollisionObject2D:
		enemy.collision_layer = 4  # Layer 3
	
	# Configure HitboxComponent - should be layer 3 and detect bullets (layer 4)
	if enemy.has_node("HitboxComponent"):
		var hitbox = enemy.get_node("HitboxComponent")
		hitbox.collision_layer = 4   # Layer 3
		hitbox.collision_mask = 8    # Layer 4 (bullets)
		
		# Connect to HealthComponent if available
		if enemy.has_node("HealthComponent"):
			var health_comp = enemy.get_node("HealthComponent")
			hitbox.healthComponent = health_comp
			
			# Use a unique callable for this enemy
			var callable = Callable(self, "_on_enemy_died").bind(enemy)
			
			# Disconnect any existing connections first
			if health_comp.is_connected("entity_died", callable):
				health_comp.disconnect("entity_died", callable)
				
			# Connect the signal
			health_comp.entity_died.connect(callable)
	
	# Configure AttackArea - should be layer 6 and detect player hitbox (layer 5)
	if enemy.has_node("AttackArea"):
		var attack_area = enemy.get_node("AttackArea")
		attack_area.collision_layer = 32  # Layer 6 (enemy attack)
		attack_area.collision_mask = 16   # Layer 5 (player hitbox)
	
	# Store in tracking dictionary
	var id = enemy.get_instance_id()
	active_enemies[id] = enemy
	current_enemies = active_enemies.size()

func _on_enemy_died(entity, enemy):
	# Get reference to the actual enemy
	var actual_enemy = enemy
	if !is_instance_valid(actual_enemy):
		actual_enemy = entity
	
	# Get instance ID for dictionary lookup
	var id = actual_enemy.get_instance_id()
	
	# Only process if this enemy is still in our tracking dict
	if active_enemies.has(id):
		active_enemies.erase(id)
		current_enemies = active_enemies.size()
		
		# CRUCIAL: Actually remove the enemy from the scene
		actual_enemy.queue_free()
		
		print("Remaining enemies: ", current_enemies)

func wave_complete():
	# Wave is complete, display notification
	display_wave_notification("Wave " + str(current_wave) + " Complete!")
	
	# Start countdown to next wave
	spawn_timer = 0.0
	
	print("Wave " + str(current_wave) + " complete!")

# UI related functions stay the same
func load_custom_font():
	# Try to load the font resource
	if ResourceLoader.exists(custom_font_path):
		custom_font = ResourceLoader.load(custom_font_path)
	else:
		push_warning("Custom font not found at path: " + custom_font_path)

func setup_wave_ui():
	# Create canvas layer
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10
	add_child(canvas_layer)
	
	# Create wave label
	wave_label = Label.new()
	canvas_layer.add_child(wave_label)
	
	# Apply font to wave label
	if custom_font:
		wave_label.add_theme_font_override("font", custom_font)
		wave_label.add_theme_font_size_override("font_size", 36)
	
	# Configure wave label
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wave_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	
	# Position
	wave_label.size = Vector2(400, 100)
	wave_label.position = Vector2(
		(get_viewport_rect().size.x - wave_label.size.x) / 2,
		100
	)
	
	# Hide initially (we'll show it when needed)
	wave_label.visible = false
	
	# Create count label
	count_label = Label.new()
	canvas_layer.add_child(count_label)
	
	# Apply font to count label
	if custom_font:
		count_label.add_theme_font_override("font", custom_font)
		count_label.add_theme_font_size_override("font_size", 24)
	
	# Configure count label
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.add_theme_color_override("font_color", Color(1, 1, 1))
	
	# Position
	count_label.size = Vector2(200, 50)
	count_label.position = Vector2(
		get_viewport_rect().size.x - count_label.size.x - 20,
		20
	)
	
	# Set initial text
	update_enemy_count()

func display_wave_notification(text: String):
	# Set the text
	wave_label.text = text
	
	# Make visible
	wave_label.visible = true
	
	# Reset any existing animations
	wave_label.modulate = Color(1, 1, 1, 0)  # Start transparent
	wave_label.scale = Vector2(0.5, 0.5)     # Start small
	
	# Create a sequence of animations
	var tween = create_tween()
	
	# Fade in and scale up
	tween.tween_property(wave_label, "modulate", Color(1, 1, 1, 1), 0.3)
	tween.parallel().tween_property(wave_label, "scale", Vector2(1.2, 1.2), 0.3)
	
	# Scale back to normal
	tween.tween_property(wave_label, "scale", Vector2(1, 1), 0.2)
	
	# Wait a moment
	tween.tween_interval(1.0)
	
	# Fade out
	tween.tween_property(wave_label, "modulate", Color(1, 1, 1, 0), 0.5)
	
	# Hide when done
	tween.tween_callback(func(): wave_label.visible = false)

func update_enemy_count():
	if count_label:
		if wave_in_progress:
			count_label.text = "Enemies: " + str(current_enemies)
		else:
			count_label.text = "Next wave in: " + str(int(spawn_interval - spawn_timer))
			
		# Color coding based on number of enemies
		if current_enemies > 0:
			count_label.add_theme_color_override("font_color", Color(0, 0, 0)) # Black
		else:
			count_label.add_theme_color_override("font_color", Color(0, 0.5, 0, 1)) # Green
