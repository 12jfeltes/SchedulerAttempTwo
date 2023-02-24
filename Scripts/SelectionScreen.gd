extends Control


func _ready():
	Constants.selectedResident = null
	Constants.loadExistingSchedule = false
	pass

func _on_create_schedule_button_pressed():
	get_tree().change_scene_to_file("res://ScreenNodes/ShiftCalendar.tscn")
	pass


func _on_load_schedule_button_pressed():
	#Dictionaries.loadCalendars() - should already be done on Dictionaries._ready()
	#If a calendar does not yet exist for the block
	#Dictionaries.savedCalendars["Calendars"].has(Constants.currentBlock) == false
	
	var blockCalendar = {}
	if Dictionaries.savedCalendars["Calendars"].has(Constants.currentBlock) == true:
		blockCalendar = Dictionaries.savedCalendars["Calendars"][Constants.currentBlock]
	
	Dictionaries.AssembledCalendar["Shifts"] = blockCalendar
	Dictionaries.populateShiftsPerResidentDict()
	
	Constants.loadExistingSchedule = true
	
	get_tree().change_scene_to_file("res://ScreenNodes/ShiftCalendar.tscn")
	pass
