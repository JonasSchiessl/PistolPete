extends CharacterBody2D

var positionB: Vector2
var directionB: Vector2
var timer = 0.0 
@export var speed = 2000
@export var lifetime = 2.0  
@export var bullet_damage = 5
@export var knockback_force = 100

func _ready() -> void:
	global_position = positionB
	global_rotation = directionB.angle()

func _physics_process(delta):
	velocity = directionB * speed
	move_and_slide()
	
	# If we hit something, remove the bullet and apply damage if applicable
	if get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		var collider = collision.get_collider()
		print("Bullet hit:", collider.name, "of type:", collider.get_class())
		
		var should_destroy = check_collision(collision)
		if should_destroy:
			print("Destroying bullet")
			queue_free()
		else:
			print("Not destroying bullet")
	 
	# Lifetime timer as a fallback
	timer += delta
	if timer >= lifetime:
		queue_free()

func check_collision(collision) -> bool:
	var collider = collision.get_collider()
	var should_destroy = true
	
	# First check if the collider is a TileMap
	if collider is TileMap or collider.is_in_group("ground"):
		# Always destroy bullets when hitting the ground/walls
		print("Hit ground/wall, destroying bullet")
		return true
	
	# Now check for different types of damage handlers
	# First check for a HitboxComponent as a child
	var hitbox = collider.get_node_or_null("HitboxComponent")
	if hitbox and hitbox.has_method("damage"):
		# Create an Attack instance
		var attack = Attack.new()
		attack.attackDamage = bullet_damage
		attack.knockbakForce = knockback_force
		attack.attackPosition = global_position
		
		# Apply damage to the hitbox
		hitbox.damage(attack)
		print("Hit entity with hitbox component! Damage:", bullet_damage)
	# Then check for direct hitbox (if the collider itself is a hitbox)
	elif collider is Area2D and collider.has_method("damage"):
		# Create an Attack instance
		var attack = Attack.new()
		attack.attackDamage = bullet_damage
		attack.knockbakForce = knockback_force
		attack.attackPosition = global_position
		
		# Apply damage to the collider
		collider.damage(attack)
		print("Hit a direct hitbox! Damage:", bullet_damage)
	# Then check for a health component
	elif collider.get_node_or_null("HealthComponent") and collider.get_node_or_null("HealthComponent").has_method("damage"):
		var health_component = collider.get_node_or_null("HealthComponent")
		
		# Create an Attack instance
		var attack = Attack.new()
		attack.attackDamage = bullet_damage
		attack.knockbakForce = knockback_force
		attack.attackPosition = global_position
		
		# Apply damage to the health component
		health_component.damage(attack)
		print("Hit entity with health component! Damage:", bullet_damage)
	# Then check for damage method on the collider itself
	elif collider.has_method("damage"):
		# Create an Attack instance
		var attack = Attack.new()
		attack.attackDamage = bullet_damage
		attack.knockbakForce = knockback_force
		attack.attackPosition = global_position
		
		# Apply damage directly to the collider
		collider.damage(attack)
		print("Hit entity with damage method! Damage:", bullet_damage)
	elif collider.is_in_group("bulletproof"):
		# Objects that block bullets
		print("Hit bulletproof object")
		should_destroy = true
	elif collider.is_in_group("pass_through"):
		# Objects that bullets should pass through
		print("Hit pass-through object")
		should_destroy = false
	else:
		# Default behavior for any other object
		print("Hit unknown object:", collider.name)
		should_destroy = true
	
	return should_destroy
