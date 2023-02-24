extends Control

var shiftID = null
var residentSelected = null
@onready var InfoText = $MarginContainer/VBoxContainer/InfoText
@onready var CurrentResident = $MarginContainer/VBoxContainer/CurrentResident
@onready var itemList = $MarginContainer/VBoxContainer/ScrollContainer/ItemList
@onready var residentList = $MarginContainer/VBoxContainer/OptionButton 

func _ready():
	visible = false
	Signals.connect("openAssignShiftPanel", openPanel)
	pass


func openPanel(ID):
	shiftID = ID
	visible = true
	fillShiftInfoText()
	fillResidentList()
	return

func fillShiftInfoText():
	if shiftID != null:
		var shiftInfo = Dictionaries.AssembledCalendar["Shifts"][shiftID]
		var date = Time.get_datetime_string_from_datetime_dict(shiftInfo["Date"], true)
		var weekday = Calculations.getStringWeekdayName(Calculations.getDayOfWeek(shiftInfo["Date"]))
		var shiftName = shiftInfo["ShiftName"]
		var currentRes = shiftInfo["Resident"]
		
		InfoText.text = shiftName + ": " + weekday + " - " + str(date)
		CurrentResident.text = "Current Resident: " + currentRes
	return

func fillResidentList():
	residentList.clear()
	var Residents = Dictionaries.ResidentDict.keys()
	for resident in Residents:
		residentList.add_item(resident)
	residentList.add_item("Unfilled")
	return

func _on_option_button_item_selected(index):
	residentSelected = residentList.get_item_text(index)
	pass

func _on_submit_button_pressed():
	submitAssignment()
	visible = false
	Signals.emit_signal("filterCalendar")
	pass

func submitAssignment():
	#print(residentSelected)
	if residentSelected == null: 
		print("No resident selected")
		return
	#Check if valid shift
	if residentSelected != "Unfilled":
		print("here")
		if Calculations.isValidShift(shiftID, residentSelected) == false:
			print("Not valid shift")
			Signals.emit_signal("popUpMessage", "Not Valid Shift Addition")
			return
	
	#assign to Dictionary
	Dictionaries.AssembledCalendar["Shifts"][shiftID]["Resident"] = residentSelected
	if residentSelected != "Unfilled":
		Dictionaries.ShiftTimesPerResident["Shifts"][residentSelected].append(shiftID)
	Signals.emit_signal("filterCalendar")
	return

func _on_button_pressed():
	#Close [x] button
	visible = false
	pass



