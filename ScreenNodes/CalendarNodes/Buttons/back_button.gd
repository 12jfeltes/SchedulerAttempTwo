extends Button


func _ready():
	pass 

func _on_pressed():
	#Reset Variables
	Constants.selectedResident = null
	Constants.loadExistingSchedule = false
	
	get_tree().change_scene_to_file("res://ScreenNodes/SelectionScreen.tscn")
	pass
