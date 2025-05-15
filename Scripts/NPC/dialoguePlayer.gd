extends Control

@export_file("*.json") var file

signal dialogueFinished

var dialogue = []
var currentDialogue = 0
var dialogueActive = false

func _ready():
	$Panel.visible = false
	
func start():
	if dialogueActive:
		return
	dialogueActive = true
	$Panel.visible = true
	dialogue = loadDialogue()
	currentDialogue = -1
	nextScript()

func loadDialogue():
	file = FileAccess.open(file, FileAccess.READ)
	var content = JSON.parse_string(file.get_as_text())
	return content
	
func _input(event: InputEvent) -> void:
	if !dialogueActive:
		return 
	if event.is_action_pressed("interact"):
		$Click.play()
		nextScript()

func nextScript():
	currentDialogue += 1
	if currentDialogue >= len(dialogue):
		dialogueActive = false
		$Panel.visible = false
		emit_signal("dialogueFinished")
		return 
	
	$Panel/VBoxContainer/Name.text = dialogue[currentDialogue]["name"]
	$Panel/VBoxContainer/Text.text = dialogue[currentDialogue]["text"]
