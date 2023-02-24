extends Control


func _ready():
	pass

func _on_left_button_pressed():
	#reload calendar back one month
	var month = int(Constants.currentBlock) - 1
	loadMonthCalendar(month)
	pass 


func _on_right_button_2_pressed():
	var month = int(Constants.currentBlock) + 1
	loadMonthCalendar(month)
	pass


func loadMonthCalendar(block: int):
	if block < 1 or block > 13:
		Signals.emit_signal("popUpMessage", "Can't go further")
		return
	
	Constants.currentBlock = str(block)
	var blockCalendar: Dictionary = {}
	if Dictionaries.savedCalendars["Calendars"].has(Constants.currentBlock) == true:
		blockCalendar = Dictionaries.savedCalendars["Calendars"][Constants.currentBlock]
	
	Dictionaries.AssembledCalendar["Shifts"] = blockCalendar
	Dictionaries.populateShiftsPerResidentDict()
	
	Constants.loadExistingSchedule = true
	
	get_tree().change_scene_to_file("res://ScreenNodes/ShiftCalendar.tscn")
	return
