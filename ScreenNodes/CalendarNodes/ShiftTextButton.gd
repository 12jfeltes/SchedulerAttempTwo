extends Button

@export var shiftID = null


func _ready():
	pass

func setText(newText: String):
	text = newText
	setButtonTheme(newText)
	return

func setButtonTheme(text):
	if text.contains("GW"):
		theme = load("res://Media/buttonThemeGW.tres")
	elif text.contains("FFX"):
		theme = load("res://Media/buttonThemeFFX.tres")
	elif text.contains("Children"):
		theme = load("res://Media/buttonThemeChildrens.tres")
	return

func _on_pressed():
	#make sure not more than two nodes are pressed at once
	#for purposes of shift swapping
	var group = get_tree().get_nodes_in_group("TextButtons")
	var pressedButtons = 0
	for button in group:
		if button.button_pressed == true:
			pressedButtons += 1
	if pressedButtons > 2:
		button_pressed = false

	pass
