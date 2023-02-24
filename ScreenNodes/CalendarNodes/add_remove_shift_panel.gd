extends Control

var shiftID = null
var Day = null
var shiftType = null
var shiftTime = null
var Resident = null

func _ready():
	visible = false
	Signals.connect("openAddRemoveShiftPanel", openPanel)
	pass

func openPanel(ID):
	shiftID = ID
	visible = true
	fillSelectedShiftText()
	
	fillDayText()
	#fill shiftType
	#fill time
	return

#--------------- Remove Shift Functions ------------------------

func fillSelectedShiftText():
	var selectedShiftText = $MarginContainer/VBoxContainer/SelectedShift
	if shiftID != null:
		var shiftInfo = Dictionaries.AssembledCalendar["Shifts"][shiftID]
		var date = Time.get_datetime_string_from_datetime_dict(shiftInfo["Date"], true)
		var weekday = Calculations.getStringWeekdayName(Calculations.getDayOfWeek(shiftInfo["Date"]))
		var shiftName = shiftInfo["ShiftName"]
		var currentRes = shiftInfo["Resident"]
		Resident = currentRes
		
		selectedShiftText.text = shiftName + ": " + weekday + " - " + str(date)
	return

func _on_remove_shift_button_pressed():
	#remove shift from Dictionaries.AssembledCalendar and from ShiftTimesPerResident
	if shiftID != null:
		Dictionaries.AssembledCalendar["Shifts"].erase(shiftID)
		Dictionaries.ShiftTimesPerResident["Shifts"][Resident].erase(shiftID)
	
	Signals.emit_signal("filterCalendar")
	visible = false
	pass

#------------------- Add Shift Functions -------------------------
func fillDayText():
	var OptionDayList = $MarginContainer/VBoxContainer/OptionDay
	var unixBlockStartDate = Time.get_unix_time_from_datetime_dict(Calculations.pullCurrentBlockStartDate())
	var blockDuration = Dictionaries.CalendarDict[Constants.currentBlock]["Days"]
	for i in range(0,blockDuration):
		var unixDay = unixBlockStartDate + (i * Constants.UnixDay)
		var stringDate = Time.get_datetime_string_from_unix_time(unixDay, true)
		OptionDayList.add_item(str(stringDate))
	return

func _on_option_day_item_selected(index):
	var OptionDayList = $MarginContainer/VBoxContainer/OptionDay
	Day = Time.get_datetime_dict_from_datetime_string(OptionDayList.get_item_text(index),false)
	pass
