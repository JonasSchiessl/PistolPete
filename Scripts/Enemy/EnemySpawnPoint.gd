extends Marker2D
class_name EnemySpawnPoint

@export var active: bool = true
@export var spawn_direction: Vector2 = Vector2.LEFT

func _ready():
	# Add to spawn points group
	add_to_group("enemy_spawn_points")
	
	# Optional: Add visual indicator in editor only
	if Engine.is_editor_hint():
		var gizmo = create_editor_gizmo()

# Optional: Create a simple arrow gizmo to see spawn direction in editor
func create_editor_gizmo():
	var gizmo = Control.new()
	gizmo.custom_minimum_size = Vector2(20, 20)
	add_child(gizmo)
	
	gizmo.draw.connect(func():
		var color = Color.GREEN if active else Color.RED
		gizmo.draw_circle(Vector2.ZERO, 5, color)
		gizmo.draw_line(Vector2.ZERO, spawn_direction * 15, color, 2)
		gizmo.draw_triangle(spawn_direction * 15, spawn_direction.normalized(), 5, color)
	)
	
	return gizmo
