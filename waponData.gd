extends Resource
class_name WeaponData

@export var weapon_name: String = "Pistol"
@export var max_ammo: int = 6
@export var reload_time: float = 1.5
@export var bullet_scene: PackedScene
@export var bullet_damage: int = 5
@export var bullet_speed: float = 2000
@export var bullet_knockback: float = 100
@export var bullet_lifetime: float = 2.0
