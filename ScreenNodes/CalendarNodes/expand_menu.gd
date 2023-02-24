extends Control

@onready var Menu = $Control/MenuCont

func _ready():
	Menu.visible = false
	pass


func _on_expand_button_toggled(button_pressed):
	if button_pressed == true:
		Menu.visible = true
	elif button_pressed == false:
		Menu.visible = false
	pass
