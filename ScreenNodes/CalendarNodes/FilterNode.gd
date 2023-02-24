extends Control

@onready var lineEdit = $HBoxContainer/LineEdit
@onready var filterButton = $HBoxContainer/Button

func _ready():
	pass



func _on_button_pressed():
	#get line edit text and save that info
	var text = lineEdit.text
	if text == null or text == "":
		Constants.selectedResident = null
	else:
		Constants.selectedResident = text
	
	#Signal to refresh the Calendar with only the selected resident info
	Signals.emit_signal("filterCalendar")
	pass
