extends Control

@onready var label = $Label


func _ready():
	Signals.connect("popUpMessage", _popUpMessage)
	pass

func _popUpMessage(message: String):
	label.text = message
	visible = true
	await get_tree().create_timer(1.5).timeout
	
	label.text = ""
	visible = false
	return
