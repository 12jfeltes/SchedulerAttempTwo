extends MarginContainer

@onready var DateText = $Scroll/VBoxContainer/DateText
@onready var shiftButton = preload("res://ScreenNodes/CalendarNodes/shift_text_button.tscn")
@onready var Vbox = $Scroll/VBoxContainer
@onready var DateButton = $Scroll/VBoxContainer/Date

func _ready():
	pass

func setText(newText: String):
	if DateButton == null: return
	#Used for Dates
	DateButton.text = newText
	return

func setNextLineText(newText: String):
	if Vbox == null: return
	#Used for non-clickable Call Day text
	var newFlatButton = Button.new()
	newFlatButton.flat = true
	newFlatButton.disabled = true
	newFlatButton.alignment = HORIZONTAL_ALIGNMENT_LEFT
	newFlatButton.text = newText
	Vbox.add_child(newFlatButton)
	return

func addNewShiftButton(shiftID, newText: String):
	var newButton = shiftButton.instantiate()
	newButton.shiftID = shiftID
	newButton.setText(newText)
	#set button background theme color based on shift type
	Vbox.add_child(newButton)
	return

func clearShifts():
	for child in Vbox.get_children():
		if child.is_in_group("TextButtons"):
			Vbox.remove_child(child)
	return

