extends CharacterBody2D

@export var character_texture: Texture2D
@export_file("*.json") var dialogue_file_path: String
@export var gravity: float = 800.0

var isChatting = false
var player 
var playerInChatZone = false
var hasAlreadyChatted = false


func _physics_process(delta):
	# Apply gravity
	velocity.y += gravity * delta
	move_and_slide()

func _ready() -> void:
	$IntreractionUI.visible = false
	$Sprite2D.texture = character_texture

func _process(delta):
	if playerInChatZone and Input.is_action_just_pressed("interact") and !isChatting and !hasAlreadyChatted:
		$Dialogue.file = dialogue_file_path
		$Dialogue.start()
		$IntreractionUI.visible = false
		isChatting = true
		hasAlreadyChatted = true
		
func _on_chat_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		playerInChatZone = true 
		if !isChatting and !hasAlreadyChatted:
			$IntreractionUI.visible = true
	

func _on_chat_detection_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		playerInChatZone = false
		hasAlreadyChatted = false 
		$IntreractionUI.visible = false
		

func _on_dialogue_dialogue_finished() -> void:
	isChatting = false
