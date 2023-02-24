extends Control

@onready var Grid = $V/GridContainer
@onready var Box = preload("res://ScreenNodes/CalendarNodes/DayGridBox.tscn")


func _ready():
	Signals.connect("filterCalendar", _filterCalendar)
	Signals.connect("swapShifts", _swapShifts)
	Signals.connect("showPossibleTrades", showPossibleTrades)
	var blockStartDate = Calculations.pullCurrentBlockStartDate()
	
	#Set Correct Residents to ResidentDict based on the chosen block
	setResidentsForBlock()
	
	#Create Base Empty Calendar
	addDayBoxes()
	assignDatesToBoxes(blockStartDate)
	
	if Constants.loadExistingSchedule == true:
		loadExistingSchedule()
	
	if Constants.loadExistingSchedule == false:
		Dictionaries.clearDictionaries()
	pass

func _process(delta):
	if Input.is_action_just_pressed("ui_text_completion_replace"): #tab
		var blockStartDate = Calculations.pullCurrentBlockStartDate()
		print("start calculating shifts: " + str(Time.get_ticks_msec()))
		#Fill dictionary with shifts
		
		Calculations.populateShiftsToDict(blockStartDate)
		print("end calculating shifts: " + str(Time.get_ticks_msec()))
		
		#Visually add text to calendar
		visuallyAddShiftsToCal(blockStartDate)
		print("end visually adding shifts: " + str(Time.get_ticks_msec()))
		
		#Backup Call Days - add text to calendar
		visuallyAddBackupCallDays(blockStartDate)
		
		#Dev Tools
		printCalendarReport()
		
	if Input.is_action_just_pressed("ui_x"):
		#Calculate possible shift trades for selected shift and highlight them
		showPossibleTrades()
	pass


#---------------- Calendar Box Structure ------------------------
func addDayBoxes():
	for i in range(1,36): 
		var newBox = Box.instantiate()
		newBox.setText(str("Blank Date"))
		Grid.add_child(newBox)
	return 

func startingBoxIndex(startingDate):
	#calculates the index of the child Box within Grid that is associated with the 1st date of the block
	var startingDateUnix = Time.get_unix_time_from_datetime_dict(startingDate)
	var startingWeekday = Calculations.getDayOfWeek(startingDate)
	var startingBoxIndex = startingWeekday - 1
	return startingBoxIndex

func assignDatesToBoxes(startingDate):
	var startingDateUnix = Time.get_unix_time_from_datetime_dict(startingDate)
	var startingBoxNumber = startingBoxIndex(startingDate)
	
	for i in range(0, Grid.get_child_count() - startingBoxNumber):
		var newDateUnix = startingDateUnix + (86400 * i)
		var newDate = Time.get_date_dict_from_unix_time(newDateUnix)
		var dayOfWeek = Calculations.getDayOfWeek(newDate)
		var weekdayName = Calculations.getStringWeekdayName(dayOfWeek)
		var correctBoxIndex = startingBoxNumber + i
		if correctBoxIndex >= Grid.get_child_count():
			correctBoxIndex -= Grid.get_child_count()
		
		var correctBox = Grid.get_child(correctBoxIndex)
		correctBox.setText(str(newDate["month"]) + "/" + str(newDate["day"]) + " - " + weekdayName)
	return

func visuallyAddShiftsToCal(startingDate, overrideArrayOfShiftIDs = null):
	var shifts = Dictionaries.AssembledCalendar["Shifts"]
	var filteredResident = Constants.selectedResident
	var shiftIDs: Array = shifts.keys()
	if overrideArrayOfShiftIDs != null: shiftIDs = overrideArrayOfShiftIDs
	
	for key in shiftIDs:
		#1. Find proper box to paste shift into
		var dateOfShift = shifts[key]["Date"] #Date is just INT MM/DD of current block
		var dayOfBlock = Calculations.daysBetweenDates(startingDate, dateOfShift) #starts at Day 0
		var boxIndex = startingBoxIndex(startingDate) + dayOfBlock
		if boxIndex >= Grid.get_child_count():
			boxIndex -= Grid.get_child_count()
		var correctBoxNode = Grid.get_child(boxIndex)
		
		#2. Apply Resident Filter if there is one
		var assignedResident = shifts[key]["Resident"]
		if filteredResident == null or assignedResident.contains(filteredResident) or overrideArrayOfShiftIDs != null:
			#3. Paste in the shift info text
			var startTimeUnix = Time.get_unix_time_from_datetime_dict(shifts[key]["Date"])
			var startTimeString = Time.get_time_string_from_unix_time(startTimeUnix).trim_suffix(Time.get_time_string_from_unix_time(startTimeUnix).right(3)) #str(shifts[key]["Date"]["hour"]) + str(shifts[key]["Date"]["minute"])
			var endTimeUnix = startTimeUnix + (shifts[key]["Duration"] * Constants.UnixHour)
			var endTimeString = Time.get_time_string_from_unix_time(endTimeUnix).trim_suffix(Time.get_time_string_from_unix_time(endTimeUnix).right(3)) #str(endTimeDict["hour"]) + str(endTimeDict["minute"])
			
			correctBoxNode.addNewShiftButton(
				key, shifts[key]["ShiftName"]
					+ " (" + str(startTimeString) + "-"
					+ str(endTimeString) + ") \n" + assignedResident
					)
	#print(shifts)
	return

func visuallyAddBackupCallDays(startingDate):
	var dict = Dictionaries.BackupCallDict["Backup"]
	var filteredResident = Constants.selectedResident
	var startOfMonthUnix = Time.get_unix_time_from_datetime_dict(startingDate)
	var endOfMonthUnix = Time.get_unix_time_from_datetime_string(Dictionaries.CalendarDict[Constants.currentBlock]["End"]) + Constants.UnixDay
	
	#Add some fake back up days here ->
#	for resident in dict.keys():
#		for i in range(30):
#			randomize()
#			var randomDate = {"day":randi_range(1,28), "month":randi_range(1,12), "year":2023}
#			var existingBackupDates = dict[resident]
#			existingBackupDates.append(randomDate)
#			Dictionaries.BackupCallDict["Backup"][resident] = existingBackupDates
#	print(str(Dictionaries.BackupCallDict["Backup"]))
	
	for resident in dict.keys():
		if filteredResident == null or filteredResident == resident:
			var backupDays = dict[resident]
			for day in backupDays:
				#Check if day falls within this calendar month
				var unixBackupDay = Time.get_unix_time_from_datetime_dict(day)
				if unixBackupDay > startOfMonthUnix and unixBackupDay < endOfMonthUnix:
					#Add Backup Call Text to correct Grid Box Node
					var dayOfBlock = Calculations.daysBetweenDates(startingDate, day)
					var boxIndex = startingBoxIndex(startingDate) + dayOfBlock
					var correctBoxNode = Grid.get_child(boxIndex)
					
					correctBoxNode.setNextLineText("On Call: " + resident)
	return


func loadExistingSchedule():
	var blockStartDate = Calculations.pullCurrentBlockStartDate()
	visuallyAddShiftsToCal(blockStartDate)
	visuallyAddBackupCallDays(blockStartDate)
	printCalendarReport()
	return

func setResidentsForBlock():
	#Placeholder function. Currently selects residents based on who is already in the block
	var block = int(Constants.currentBlock)
	var defaultResidentInfo = {"PGY": 1, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false}
	#Step 1: Figure out if there's a saved calendar for this block
	var savedCal = null
	if Dictionaries.savedCalendars["Calendars"].has(block):
		savedCal = Dictionaries.savedCalendars["Calendars"][block]
	
	#If savedCal == null: do nothing, keep default ResidentDict
	#If there is an existing calendar, ResidentDict = just those residents
	if savedCal != null:
		var includedResidents = []
		var cal = Dictionaries.AssembledCalendar["Shifts"]
		for shiftID in cal.keys():
			var resName = cal[shiftID]["Resident"]
			if includedResidents.has(resName) == false and resName != "Unfilled":
				includedResidents.append(resName)
		#Replace existing ResidentDict with correct residents for the month
		Dictionaries.ResidentDict = {}
		for resident in includedResidents:
			var PGY = Dictionaries.AllResidents["Residents"][resident]["PGY"]
			#var Block = TODO
			var residentInfo = defaultResidentInfo.duplicate()
			residentInfo["PGY"] = PGY
			Dictionaries.ResidentDict[resident] = residentInfo
	
	return

#------------------ Misc Functions ------------------------------
func _filterCalendar():
	#clear text from existing boxes.
	for dateBox in Grid.get_children():
		dateBox.call("clearShifts")
	
	#fill back in the boxes
	#assignDatesToBoxes(Calculations.pullCurrentBlockStartDate())
	visuallyAddShiftsToCal(Calculations.pullCurrentBlockStartDate())
	visuallyAddBackupCallDays(Calculations.pullCurrentBlockStartDate())
	return

func filterBySelectedShifts(shiftIDArray: Array):
	for dateBox in Grid.get_children():
		dateBox.call("clearShifts")
	
	visuallyAddShiftsToCal(Calculations.pullCurrentBlockStartDate(), shiftIDArray)
	return

func _swapShifts():
	#find all the shifts highlighted and their associated shiftIDs
	var highlightedShiftIDs = []
	var shifts = get_tree().get_nodes_in_group("TextButtons")
	for node in shifts:
		if node.button_pressed == true:
			highlightedShiftIDs.append(node.shiftID)
	#if != 2 highlighted shifts: return
	if highlightedShiftIDs.size() != 2:
		print("Invalid Swap. Incorrect Number of Highlighted Shifts")
		Signals.emit_signal("popUpMessage", "Invalid Swap. Incorrect Number of Highlighted Shifts")
		return
	
	#check if valid swap and swap shifts in AssembledCalendar dict
	if Calculations.isValidSwap(highlightedShiftIDs[0], highlightedShiftIDs[1]) == false:
		print("Invalid Swap")
		Signals.emit_signal("popUpMessage", "Invalid Swap")
		return
	
	print("Valid Swap")
	Calculations.swapShiftsInDict(highlightedShiftIDs[0], highlightedShiftIDs[1])
	
	#TODO: Save Calendar
	
	_filterCalendar()
	return


func showPossibleTrades(shiftIDOverride = null):
	var highlightedShifts = getHighlightedShiftButtons() 
	if shiftIDOverride != null: highlightedShifts = [shiftIDOverride]
	print("highlighted shifts = " + str(highlightedShifts))
	if highlightedShifts.size() != 1:
		print("Please select 1 shift"); return
	var chosenShiftID = highlightedShifts[0]
	
	var possibleTrades = Calculations.getAllValidSwaps(chosenShiftID)
	possibleTrades.append(chosenShiftID)
	print("Swaps available: " + str(possibleTrades.size() - 1))
	
	filterBySelectedShifts(possibleTrades)
	return

#--------------------- Dev Tools --------------------------------
func getHighlightedShiftButtons():
	var highlightedShiftIDs = []
	var shifts = get_tree().get_nodes_in_group("TextButtons")
	for node in shifts:
		if node.button_pressed == true:
			highlightedShiftIDs.append(node.shiftID)
	return highlightedShiftIDs

func printCalendarReport():
	#prints several statistics to quickly eval if calendar is working well
	var resShifts = Dictionaries.ShiftTimesPerResident["Shifts"]
	var shiftCalendar = Dictionaries.AssembledCalendar["Shifts"]
	
	#How Many Residents vs how many Shifts this Block
	var numOfResidentsThisBlock = resShifts.keys().size()
	var numOfTotalShiftsThisBlock = shiftCalendar.keys().size()
	print("Total Residents = " + str(numOfResidentsThisBlock))
	print("Total Shifts This Block = " + str(numOfTotalShiftsThisBlock))
	
	#Do residents have enough shifts?
	var tmpShiftNumberDict = {}
	var totalShiftsNeedFilled = 0
	for resident in resShifts.keys():
		var numOfShiftsForRes = resShifts[resident].size()
		var maxShifts = Calculations.maxNumOfShifts(resident)
		totalShiftsNeedFilled += maxShifts
		tmpShiftNumberDict[resident] = str(numOfShiftsForRes) + " / " + str(maxShifts)
	print("Total Shifts That Residents Need = " + str(totalShiftsNeedFilled))
	print(tmpShiftNumberDict)
	
	#2. What is the distribution of shifts (A, B, FFX, etc) per resident
#	var tmpShiftDistributionDict = []
#	for resident in resShifts.keys():
#		var maxShifts
#		var AShifts = 
#		var OtherGW =
#		var FFX = 
#		var Childrens = 
#		tmpShiftDistributionDict[resident] =
	
	
	return
