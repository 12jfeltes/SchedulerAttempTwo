extends Node

#------- Create Calendar Dictionaries ----------
func getDayOfWeek(date):
	#Requires input as date dictionary (TODO: be inclusive of datetime string)
	if typeof(date) != TYPE_DICTIONARY:
		date = Dictionaries.defaultStartingDate
	var unixTime = Time.get_unix_time_from_datetime_dict(date)
	var formattedDate = Time.get_datetime_dict_from_unix_time(unixTime)
	return formattedDate["weekday"]

func getStringWeekdayName(weekday: int):
	var name = "Monday"
	match weekday:
		1: name = "Monday"
		2: name = "Tuesday"
		3: name = "Wednesday"
		4: name = "Thursday"
		5: name = "Friday"
		6: name = "Saturday"
		0: name = "Sunday"
	return name

func nextWeekday(currentDay: int):
	var nextDay = currentDay + 1
	if nextDay >= 7: nextDay -= 7
	return nextDay

func nextCalendarDate(calendarDay):
	var startingDateUnix = Time.get_unix_time_from_datetime_dict(calendarDay)
	var nextDateUnix = startingDateUnix + 86400
	var nextCalendarDay = Time.get_datetime_dict_from_unix_time(nextDateUnix)
	return nextCalendarDay

func daysBetweenDates(dateOne, dateTwo):
	var dateOneUnix = Time.get_unix_time_from_datetime_dict(dateOne)
	var dateTwoUnix = Time.get_unix_time_from_datetime_dict(dateTwo)
	var days = abs(floor((dateTwoUnix - dateOneUnix) / 86400 ))
	return days

func getNumberOfDaysInBlock(blockNumber): #TODO
	#subtract last and first days of block
	return

func clearAssembledCalendar():
	Dictionaries.AssembledCalendar["Shifts"].clear()
	return

func addBlankShiftEntries(startingDate):
	if typeof(startingDate) != TYPE_DICTIONARY:
		startingDate = Dictionaries.defaultStartingDate
	var startingDateUnix = Time.get_unix_time_from_datetime_dict(startingDate)
	var startingWeekday = getDayOfWeek(startingDate)
	var block = Constants.currentBlock
	
	for i in range(0, Dictionaries.CalendarDict[block]["Days"]):
		#set new date and day of week
		var unixDate = startingDateUnix + (86400 * i)
		var newWeekday = Time.get_datetime_dict_from_unix_time(unixDate)["weekday"]
		var newDate = Time.get_datetime_dict_from_unix_time(unixDate)
		
		#for each entry, ->
		for shiftType in Dictionaries.ShiftsAvailableDict[newWeekday]:
			#returns [ ] of each of GWA, GWC, FFX, etc
			for shift in Dictionaries.ShiftsAvailableDict[newWeekday][shiftType]:
				var startTime: float = float(Dictionaries.ShiftTimesDict[shiftType][shift]["Start"])
				#Correct for shifts starting at midnight - WIP
				if startTime == 24: startTime -= 0.01
				var duration = Dictionaries.ShiftTimesDict[shiftType][shift]["Duration"]
				var formattedDate = Time.get_datetime_dict_from_unix_time(unixDate + (startTime * Constants.UnixHour))
				
				Dictionaries.AssembledCalendar["Shifts"][str(randi())] = {
						"Date": formattedDate,
						"Time": formattedDate["hour"], "Duration": duration, 
						"ShiftType": shiftType, "ShiftName": shift,
						"Resident": "Unfilled"}
#	print(str(Dictionaries.AssembledCalendar["Shifts"]))
	return


#------------- High Level Functions --------------------------
func populateShiftsToDict(blockStartDate): #HIGHEST FUNCTION
	var potentialSchedules: Dictionary = {}
	var bestSchedule: int = 1
	var mostPoints: int = -1000

		#Reset Assembled Calendar Dict
#		clearAssembledCalendar()
	Dictionaries.clearDictionaries()
	randomize()
		
	#Put in unfilled shifts to AssembledCalendar
	addBlankShiftEntries(blockStartDate)
	#TODO: Add additional E shifts to match the number of shifts needed for month
	
	#Block off Golden Weekends
	blockOffGoldenWeekends(blockStartDate)
	
	#Fill with residents
		#Solution 3
	#Set Night Shifts First
	residentLevelShiftSolver(blockStartDate, true)
	
		#Solution 2
	#For the remainder of the shifts
#	assignResidentsToShifts(blockStartDate)

	#Solution 1
#		assignResidentsToShiftsOriginal(blockStartDate)
#	
	#Solution # 4
	shiftSolverFour(blockStartDate)
	
#	#fill up potential schedules
#	potentialSchedules[i] = Dictionaries.AssembledCalendar["Shifts"]
#	var points = evaluateQualityOfSchedule(Dictionaries.AssembledCalendar["Shifts"])
#	print("points" + str(points))
#	if points > mostPoints:
#		mostPoints = points
#		bestSchedule = i
#	Dictionaries.clearDictionaries()
#
#	Dictionaries.AssembledCalendar["Shifts"] = potentialSchedules[bestSchedule]
#	print("best schedule #" + str(bestSchedule) + " / points = " + str(mostPoints))
#	#TODO: repopulate ShiftTimesPerResident
#	var cal = Dictionaries.AssembledCalendar["Shifts"].duplicate()
#	for shiftID in cal.keys():
#		var resident = cal[shiftID]["Resident"]
#		if resident != "Unfilled":
#			Dictionaries.ShiftTimesPerResident["Shifts"][resident].append(shiftID)
	return

func assignResidentsToShiftsOriginal(blockStartDate): #Attempt 1
	var assembledCal = Dictionaries.AssembledCalendar["Shifts"].duplicate()
	var shiftsPerRes = Dictionaries.ShiftTimesPerResident["Shifts"].duplicate()
	var ShiftIDs = assembledCal.keys()
	ShiftIDs.shuffle()
	for shiftID in ShiftIDs:
		if assembledCal[shiftID]["Resident"] == "Unfilled":
			var validResident = pickResidentForNextShift(shiftID, blockStartDate)
			#Save resident info in two dictionaries:
			if validResident != null:
				#AssembledCalendar
				assembledCal[shiftID]["Resident"] = validResident
				#ShiftTimesPerResident
				var currentResShifts = shiftsPerRes[validResident]
				currentResShifts.append(shiftID)
				shiftsPerRes[validResident] = currentResShifts
	
	Dictionaries.AssembledCalendar["Shifts"] = assembledCal
	Dictionaries.ShiftTimesPerResident["Shifts"] = shiftsPerRes
	return assembledCal

func assignResidentsToShifts(blockStartDate): #Attempt 2
	#0. Assemble Blank Dict {ID1: {res1:points, res2: points}, ID2...}
	var baseShiftIDList: Array = Dictionaries.AssembledCalendar["Shifts"].keys().duplicate()
	var currentResList: Array = Dictionaries.ResidentDict.keys().duplicate()
	var AllPointsDict: Dictionary = {} #{ID1: {res1:points, res2: points}, ID2...}
	var ChosenResidentDict: Dictionary = {} #shiftID: resident
	
	#populate empty AllPointsDict
	for shiftID in baseShiftIDList:
		if Dictionaries.AssembledCalendar["Shifts"][shiftID]["Resident"] == "Unfilled":
			AllPointsDict[shiftID] = {}
			for resident in currentResList:
				AllPointsDict[shiftID][resident] = -20
		
	for i in range(AllPointsDict.keys().size()):
		#Populate points to AllPointsDict for each shift for each resident
		for shiftID in AllPointsDict.keys():
			currentResList = AllPointsDict[shiftID].keys().duplicate()
			for resident in currentResList:
				#1. Calculate points for each shift for each resident
				if AllPointsDict[shiftID].has(resident):
					var points: int = calculatePointsForShift(shiftID, resident, blockStartDate)
					if points > -99:
						AllPointsDict[shiftID][resident] = points
					elif points <= -99:
						AllPointsDict[shiftID].erase(resident)
		#3. Prune: ChosenResidentDict = {shiftID: res}. 
			if AllPointsDict[shiftID].keys().size() == 1:
				ChosenResidentDict[shiftID] = AllPointsDict[shiftID].keys()[0]
		#3b Evaluate points
		if ChosenResidentDict.is_empty():
			var maxPoints: int = -20
			var chosenResident = null
			var chosenShiftID = null
			var keyIDs: Array = AllPointsDict.keys(); keyIDs.shuffle()
			for shiftID in keyIDs:
				var Residents = AllPointsDict[shiftID].keys().duplicate()
				Residents.shuffle()
				for resident in Residents:
					if AllPointsDict[shiftID][resident] > maxPoints:
						maxPoints == AllPointsDict[shiftID][resident]
						chosenResident = resident
						chosenShiftID = shiftID
			if chosenShiftID != null:
				ChosenResidentDict[chosenShiftID] = chosenResident
		#3d. Populate AssembledCalendar.
		if ChosenResidentDict.is_empty() == false:
			var chosenID = ChosenResidentDict.keys()[0]
			Dictionaries.AssembledCalendar["Shifts"][chosenID]["Resident"] = ChosenResidentDict[chosenID]
			Dictionaries.ShiftTimesPerResident["Shifts"][ChosenResidentDict[chosenID]].append(chosenID)
			#3e. Erase chosenShiftID from AllShifts...
			AllPointsDict.erase(chosenID)
#			currentShiftIDList.erase(chosenID)
		ChosenResidentDict.clear()
	#4. For in AllShiftsAndPoints.keys().size(): cycle through dict again.
		print("iteration done: " + str(i) + " / " + str(Dictionaries.AssembledCalendar["Shifts"].keys().size()))
	return

func residentLevelShiftSolver(blockStartDate, nightsOnly = true): #Attempt 3
	var currentShiftIDList: Array = Dictionaries.AssembledCalendar["Shifts"].keys().duplicate()
	if nightsOnly == true: currentShiftIDList = getAllNightShifts()
	var currentResList: Array = Dictionaries.ResidentDict.keys().duplicate()
	var AllPointsDict: Dictionary = {} #{ID1: {res1:points, res2: points}, ID2...}
	
	#Step 1 - pick a resident (start with PGY1s)
	for resident in currentResList:
		for i in range(maxNumOfShifts(resident)):
			AllPointsDict.clear()
	#Step 2 - Calculate Points for resident for every shift in block
			var bestPoints = -20
			var bestShiftID = null
			currentShiftIDList.shuffle()
			for shiftID in currentShiftIDList:
	#Step 3 - Assign resident to shift with highest points
				var newShiftPoints = calculatePointsForShift(shiftID, resident, blockStartDate)
				if newShiftPoints > bestPoints:
					bestPoints = newShiftPoints
					bestShiftID = shiftID
			if bestShiftID != null:
				Dictionaries.AssembledCalendar["Shifts"][bestShiftID]["Resident"] = resident
				Dictionaries.ShiftTimesPerResident["Shifts"][resident].append(bestShiftID)
				currentShiftIDList.erase(bestShiftID)
	#Step 4 - Repeat
		#print(str(resident) + " done")
	return

func shiftSolverFour(blockStartDate): #Attempt 4
	#0. Assemble Blank Dict {ID1: {res1:points, res2: points}, ID2...}
	var baseShiftIDList: Array = Dictionaries.AssembledCalendar["Shifts"].keys().duplicate()
	var currentResList: Array = Dictionaries.ResidentDict.keys().duplicate()
	var AllPointsDict: Dictionary = {} #{ID1: {res1:points, res2: points}, ID2...}
	
	#populate empty AllPointsDict
	for shiftID in baseShiftIDList:
		if Dictionaries.AssembledCalendar["Shifts"][shiftID]["Resident"] == "Unfilled":
			AllPointsDict[shiftID] = {}
			for resident in currentResList:
				AllPointsDict[shiftID][resident] = -20
		
	for i in range(AllPointsDict.keys().size()):
		#Populate points to AllPointsDict for each shift for each resident
		for shiftID in AllPointsDict.keys():
			currentResList = AllPointsDict[shiftID].keys().duplicate()
			for resident in currentResList:
				#1. Calculate points for each shift for each resident
				if AllPointsDict[shiftID].has(resident):
					var points: int = calculatePointsForShift(shiftID, resident, blockStartDate)
					if points > -99:
						AllPointsDict[shiftID][resident] = points
					elif points <= -99:
						AllPointsDict[shiftID].erase(resident)
		#3. Find shift(s) with least # of eligible residents
		var leastEligibleShifts = []
		var smallestEligibleResidents = 30
		if AllPointsDict.keys().size() == 0: print("empty dict")
		for shiftID in AllPointsDict.keys():
			var size = AllPointsDict[shiftID].keys().size()
			if size == smallestEligibleResidents:
				leastEligibleShifts.append(shiftID)
			elif size > 0 and size < smallestEligibleResidents:
				leastEligibleShifts = [shiftID]
				smallestEligibleResidents = size
		print("least eligible shifts points =  " + str(smallestEligibleResidents) + " / " + str(leastEligibleShifts))
		#3b Evaluate points for each of the eligible residents (maybe later future trees for each least eligible shift)
		#CONSIDER Future Trees Here
		var chosenShiftID = null; var chosenRes = null; var mostPoints = -99
		for shiftID in leastEligibleShifts:
			for resident in AllPointsDict[shiftID].keys():
				var points = AllPointsDict[shiftID][resident]
				if points > mostPoints:
					print("points!")
					chosenShiftID = shiftID; chosenRes = resident; mostPoints = points
		#3d. Populate AssembledCalendar.
		print("chosen shift ID = " + str(chosenShiftID))
		if chosenShiftID != null:
			Dictionaries.AssembledCalendar["Shifts"][chosenShiftID]["Resident"] = chosenRes
			Dictionaries.ShiftTimesPerResident["Shifts"][chosenRes].append(chosenShiftID)
			#3e. Erase chosenShiftID from AllShifts...
			AllPointsDict.erase(chosenShiftID)
#			currentShiftIDList.erase(chosenID)
	#4. For in AllShiftsAndPoints.keys().size(): cycle through dict again.
		print("iteration done: " + str(i) + " / " + str(baseShiftIDList.size()))
	return

func pickResidentForNextShift(shiftID, blockStartDate): #OLD
	var residentDict = Dictionaries.ResidentDict
	var pointsDict = createAPointsDict()
	var Residents = pointsDict.keys()
	Residents.shuffle()
	#For each resident, run them through the points system for this nextShift
	for resident in Residents:
		var points = calculatePointsForShift(shiftID, resident, blockStartDate)
		pointsDict[resident] = points
	var validResident = whoHasMostPoints(pointsDict)
	
	return validResident

func createAPointsDict(): #OLD
	#pointsDict = {residentName: points}
	var residentDict = Dictionaries.ResidentDict
	var pointsDict = {}
	for residentName in residentDict.keys():
		pointsDict[residentName] = 0
	return pointsDict

func whoHasMostPoints(pointsDict): #OLD
	var highestPoints = -20
	var validResident = null
	
	var Residents = pointsDict.keys()
	Residents.shuffle() #So it's not always ResPGY1-1 that gets the first six days
	for resident in Residents:
		var value = pointsDict[resident]
		if value > highestPoints:
			highestPoints = value
			validResident = resident
	#print("points = " + str(highestPoints))
	return validResident

# Restrictions / Contingencies
func calculatePointsForShift(shiftID: String, resident: String, blockStartDate): #use individual resident subdict in ResidentDict
	var shiftInfo = Dictionaries.AssembledCalendar["Shifts"][shiftID]
	var shiftType = shiftInfo["ShiftType"]
	if resident == "Unfilled": return -99 #allows func to not break when swapping shifts or adding unfilled shift
	
	var points = 0
	#HARD CUTOFFS
	points += checkAppropriatePGYLevel(shiftType, resident) #Also adds points for PGY-1s
	if points < -100: return -1000
	points += checkNumberOfShiftsThisBlock(resident)
	if points < -100: return -1000
	points += checkIfVacationWeek(resident, shiftInfo, blockStartDate)
	if points < -100: return -1000
	points += checkIfBackupCallDay(resident, shiftInfo)
	if points < -100: return -1000
	points += checkIfRequestedDayOff(resident, shiftInfo) #also does Golden Weekend
	if points < -100: return -1000
	points += enoughHoursBetweenShifts(resident, shiftInfo)
	if points < -100: return -1000
	points += noMoreThanSixInARow(resident, shiftInfo)
	if points < -100: return -1000
	points += notTooManyNights(resident, shiftInfo)
	if points < -100: return -1000
	points += internsCantMissGR(resident, shiftInfo)
	if points < -100: return -1000
	points += nonInternsNeedTwoGRs(resident, shiftInfo) #also has soft contingencies
	if points < -100: return -1000
	points += noFourthSundayOvernight(resident, shiftInfo, blockStartDate)
	if points < -100: return -1000
	points += noFirstMondayIfPreviousGWBlock(resident, shiftInfo, blockStartDate)
	if points < -100: return -1000
	#TODO Wednesday can't be only day off in the week
	
	#SOFT CUTOFFS
	points += pointsForSeniorShifts(resident, shiftInfo)
	points += pointsForConsecutiveNights(resident, shiftInfo)
	points += pointsForPGYTwoAShifts(resident, shiftInfo)
	#slightly fewer points if senior (to give them senior shifts - or just assign senior shifts first)
	points += notTooManyChildrens(resident, shiftInfo) #also prioritizes Childrens for interns on Ch. block
	points += notTooManyFFX(resident, shiftInfo)
#	points += fewerDOMAs(resident, shiftInfo)
	points += mixtureOfShiftTimes(resident, shiftInfo)
#	points += daysOffAroundVacationWeek(resident, shiftInfo, blockStartDate)
	points += pointsForInternWednesdayShifts(resident, shiftInfo)
	points += pointsForOffServiceWedMornings(resident, shiftInfo)
	#Even mixture of A shifts (after PGY-2 preference)
	#Not every weekend day on (aka if total weekend days in block >= 5, minus points)
	
	return points

#----------------- Individual Points Functions -----------------------
#HARD
func checkAppropriatePGYLevel(shiftType: String, resident: String):
	var PGY: int = Dictionaries.ResidentDict[resident]["PGY"]
	var reqLevels: Array = Dictionaries.ShiftReqDict[shiftType]["PGY"] #array
	if reqLevels.has(PGY) == false:
		return -1000
	#Giving a slight boost to PGY1s and 2s if tied with higher level residents
	#Because their shift schedules are tighter
	if PGY == 1: return 8
	if PGY == 2 or PGY == 0: return 1
	return 0

func checkNumberOfShiftsThisBlock(resident: String):
	var dict = Dictionaries.ShiftTimesPerResident["Shifts"]
	var shiftsArray: Array = dict[resident]
	var maxShiftsAllowed = maxNumOfShifts(resident) 
	if shiftsArray.size() >= maxShiftsAllowed:
		return -1000
	return 0

func checkIfVacationWeek(resident: String, shiftInfo: Dictionary, blockStartDate):
	var weeksOn = Dictionaries.ResidentDict[resident]["WeeksOn"]
	var shiftDayOfBlock: float = daysBetweenDates(blockStartDate, shiftInfo["Date"])
	var currentWeek: int = floor(shiftDayOfBlock / 7.0) + 1
	if weeksOn.has(currentWeek) == false and currentWeek <= 4:
		return -1000
	return 0

func enoughHoursBetweenShifts(resident: String, shiftInfo: Dictionary):
	var newShiftStartUnixTime: int = Time.get_unix_time_from_datetime_dict(shiftInfo["Date"])
	var newShiftEndUnixTime: int = newShiftStartUnixTime + (shiftInfo["Duration"] * Constants.UnixHour)
	
	var existingShifts: Array = Dictionaries.ShiftTimesPerResident["Shifts"][resident]
	if existingShifts == null: return 0
	for shiftID in existingShifts:
		var date = getDateFromShiftID(shiftID)
		var unixStartTime: int = Time.get_unix_time_from_datetime_dict(date)
		var unixEndTime: int = unixStartTime + (durationOfShift(shiftID) * Constants.UnixHour)
		var timeBetweenShiftsOne: int = abs(newShiftStartUnixTime - unixEndTime)
		var timeBetweenShiftsTwo: int = abs(newShiftEndUnixTime - unixStartTime)
		
		if timeBetweenShiftsOne < (12 * Constants.UnixHour) or timeBetweenShiftsTwo < (12 * Constants.UnixHour):
			return -1000
		if newShiftStartUnixTime == unixStartTime: return -1000
	return 0

func noMoreThanSixInARow(resident: String, shiftInfo: Dictionary):
	var newShiftStartUnixTime: int = Time.get_unix_time_from_datetime_dict(shiftInfo["Date"])
	var newShiftUnixDate = floor(newShiftStartUnixTime / Constants.UnixDay)
	var existingShifts: Array = Dictionaries.ShiftTimesPerResident["Shifts"][resident]
	var allShiftDays: Array = [] #just the dates for all shifts so far this month
	if existingShifts.size() < 6: return 0
	
	#Populate allShiftDays
	for shiftID in existingShifts:
		var dateDict = getDateFromShiftID(shiftID)
		var unixStartTime: int = Time.get_unix_time_from_datetime_dict(dateDict)
		var unixStartDay = floor(unixStartTime / Constants.UnixDay)
		allShiftDays.append(unixStartDay)
	
	#Check if there are 6 or more days in a row before or after this shift:
	var adjacentDaysBefore: Array = []
	var adjacentDaysAfter: Array = []
	for i in range(1,7):
		if allShiftDays.has(newShiftUnixDate - i) and adjacentDaysBefore.size() == (i-1):
			adjacentDaysBefore.append(i)
		if allShiftDays.has(newShiftUnixDate + i) and adjacentDaysAfter.size() == (i-1):
			adjacentDaysAfter.append(i)
	
	if adjacentDaysBefore.size() + adjacentDaysAfter.size() >= 6:
		#print("too many days in a row")
		return -1000
	return 0

func notTooManyNights(resident: String, shiftInfo: Dictionary):
	#Check if new shift is a night shift
	var shiftTime = shiftInfo["Date"]["hour"] #shiftInfo from AssembledShifts Dictionary
	if shiftTime > 0 and shiftTime <= 17:
		return 0 #not a night shift
	
	#Add up night shifts so far this block
	var existingShifts: Array = Dictionaries.ShiftTimesPerResident["Shifts"][resident]
	var nightShiftsSoFar: int = 0
	for shiftID in existingShifts:
		var dateDict = getDateFromShiftID(shiftID)
		var hourOfShift = dateDict["hour"]
		if hourOfShift == 0 or hourOfShift > 17:
			nightShiftsSoFar += 1
	if nightShiftsSoFar  >= 6:
		return -1000
	return 0

func checkIfBackupCallDay(resident: String, shiftInfo: Dictionary):
	var shiftDate = shiftInfo["Date"]
	var backupDict = Dictionaries.BackupCallDict["Backup"]
	var residentBackupDates = null
	if backupDict.keys().has(resident): residentBackupDates = (backupDict[resident])
	
	if residentBackupDates == null or residentBackupDates == []: return 0
	for date in residentBackupDates:
		if date["month"] == shiftDate["month"] and date["day"] == shiftDate["day"]:
			return -1000
	return 0

func checkIfRequestedDayOff(resident: String, shiftInfo: Dictionary):
	var shiftDate: Dictionary = shiftInfo["Date"]
	var dayOffDict: Dictionary = Dictionaries.RequestOffDict["DaysOff"]
	var goldenWeekendDict: Dictionary = Dictionaries.GoldenWeekendDict["DaysOff"]
	var residentDaysOff = []
	if dayOffDict.has(resident): residentDaysOff.append_array(dayOffDict[resident])
	if goldenWeekendDict.has(resident): residentDaysOff.append_array(goldenWeekendDict[resident])
	
	if residentDaysOff == null or residentDaysOff == []: return 0
	for date in residentDaysOff:
		if date["month"] == shiftDate["month"] and date["day"] == shiftDate["day"]:
			return -1000
	return 0

func internsCantMissGR(resident: String, shiftInfo: Dictionary):
	var PGY = Dictionaries.ResidentDict[resident]["PGY"]
	if PGY != 1: return 0
	
	var shiftDate: Dictionary = shiftInfo["Date"]
	var shiftWeekday: int = getDayOfWeek(shiftDate)
	var shiftTime: int = shiftDate["hour"]
	
	var isGRShift = false
	if shiftWeekday == 2 and shiftTime > 16: isGRShift = true
	if shiftWeekday == 3 and shiftTime < 13: isGRShift = true
	if isGRShift == true: return -1000
	
	return 0

func noFourthSundayOvernight(resident: String, shiftInfo: Dictionary, blockStartDate):
	#Check if resident has next block off service
	if Dictionaries.ResidentDict[resident]["NextRot"] == false: return 0
	#If so, they can't work the last Sunday overnight of the block
	var totalDaysInBlock: int = Dictionaries.CalendarDict[Constants.currentBlock]["Days"]
	var shiftDayOfBlock: float = daysBetweenDates(blockStartDate, shiftInfo["Date"])
	if totalDaysInBlock == shiftDayOfBlock and shiftInfo["Date"]["hour"] > 16:
		return -1000
	return 0

func noFirstMondayIfPreviousGWBlock(resident: String, shiftInfo: Dictionary, blockStartDate):
	var dateOfShift: Dictionary = shiftInfo["Date"]
	var prevGWRot: bool = Dictionaries.ResidentDict[resident]["PrevRotGW"]
	if prevGWRot == true and dateOfShift["day"] == blockStartDate["day"]:
		return -1000
	return 0


#SOFT
func nonInternsNeedTwoGRs(resident: String, shiftInfo: Dictionary):
	var PGY = Dictionaries.ResidentDict[resident]["PGY"]
	if PGY == 1 or PGY == 0: return 0
	
	#Check if GR shift
	var shiftDate = shiftInfo["Date"]
	var shiftWeekday = getDayOfWeek(shiftDate)
	var shiftTime = shiftDate["hour"]
	var isGRShift = false
	if shiftWeekday == 2 and shiftTime > 16: isGRShift = true
	if shiftWeekday == 3 and shiftTime < 13: isGRShift = true
	if isGRShift == false: return 0
	
	#Check if existingShifts has 2 of these shifts. If so, return -1000
	var existingShiftIDs = Dictionaries.ShiftTimesPerResident["Shifts"][resident]
	var shiftsDuringGRs = 0
	for ID in existingShiftIDs:
		var shiftDateDict = getDateFromShiftID(ID)
		var weekday = getDayOfWeek(shiftDateDict)
		if weekday == 2 and shiftDateDict["hour"] > 16: shiftsDuringGRs += 1
		if weekday == 3 and shiftDateDict["hour"] < 13: shiftsDuringGRs += 1
	if shiftsDuringGRs >= 2: return -10
	elif shiftsDuringGRs == 1: return -1
	
	return 0

func pointsForSeniorShifts(resident, shiftInfo):
	#Goal: add points for seniors who haven't gotten many senior shifts yet this block
	#2nd Goal: Make senior shifts be assigned first
	var PGY = Dictionaries.ResidentDict[resident]["PGY"]
	if PGY != 4: return 0
	var currentBlock: String = Dictionaries.ResidentDict[resident]["Block"]
	if currentBlock.contains("GW") == false: return 0
	var shiftType = shiftInfo["ShiftType"]
	var currentShifts = Dictionaries.ShiftTimesPerResident["Shifts"][resident]
	var numOfSeniorShifts = 0
	for shiftID in currentShifts:
		if Dictionaries.AssembledCalendar["Shifts"][shiftID]["ShiftType"] == "GWS":
			numOfSeniorShifts += 1
	var maxSeniorShifts = floor(maxNumOfShifts(resident) / 0.8)
	if numOfSeniorShifts < maxSeniorShifts:
		if shiftType == "GWS": return 20
		elif shiftType != "GWS": return -10
	if numOfSeniorShifts >= maxSeniorShifts:
		if shiftType == "GWS": return 5
		elif shiftType != "GWS": return 0
	return 0

func pointsForConsecutiveNights(resident: String, shiftInfo: Dictionary):
	#Disregard function if new shift is not a night shift
	if shiftInfo["Date"]["hour"] < 18: return 0
	
	var newShiftStartUnixTime: int = Time.get_unix_time_from_datetime_dict(shiftInfo["Date"])
	var existingShifts = Dictionaries.ShiftTimesPerResident["Shifts"][resident]
	var existingNightShifts: Array = []
	for shiftID in existingShifts:
		var dateDict = getDateFromShiftID(shiftID)
		var unixStartTime: int = Time.get_unix_time_from_datetime_dict(dateDict)
		if dateDict["hour"] >= 18: existingNightShifts.append(unixStartTime)
		
		#Points for connected night shifts
		var timeDifference = abs(unixStartTime - newShiftStartUnixTime)
		if timeDifference >= (20 * Constants.UnixHour) and timeDifference <= (28 * Constants.UnixHour):
			if dateDict["hour"] >= 18:
				return 50
	
	#Non-connected existing night shifts: subtract points
	for unixShiftTime in existingNightShifts:
		if abs(newShiftStartUnixTime - unixShiftTime) > (40 * Constants.UnixHour):
			return -15
	
	if existingNightShifts.is_empty():
		var PGY: int = Dictionaries.ResidentDict[resident]["PGY"]
		if getDayOfWeek(shiftInfo["Date"]) == 3:
			if PGY == 1: return 10
			elif PGY == 2: return 5
	
	return 0

func pointsForPGYTwoAShifts(resident: String, shiftInfo: Dictionary):
	#Check if PGY2 and if we're evaluating an A shift
	var PGY = Dictionaries.ResidentDict[resident]["PGY"]
	var newShiftType = shiftInfo["ShiftType"]
	if PGY != 2 or newShiftType != "GWA": return 0
	
	#Calculate # of A shifts so far
	var existingShiftIDs = Dictionaries.ShiftTimesPerResident["Shifts"][resident]
	var existingAShifts = 0
	var cal = Dictionaries.AssembledCalendar["Shifts"]
	for ID in existingShiftIDs:
		var existingShiftType = cal[ID]["ShiftType"]
		if existingShiftType == "GWA":
			existingAShifts += 1
	
	#Give points to the PGY2 with <50% A shifts
	var totalShiftsThisBlock = maxNumOfShifts(resident)
	if existingAShifts < float(totalShiftsThisBlock) * 0.5: 
		return 6
	
	return 0

func notTooManyChildrens(resident: String, shiftInfo: Dictionary):
	#If on Childrens block, you get points for Childrens shifts
	var shiftType = shiftInfo["ShiftType"]
	if shiftType.contains("Childrens") == false: return 0
	
	#TODO if not completed Childrens, cannot give to PGY1
#	if Dictionaries.ResidentDict[resident]["PGY"] == 1 and currentBlock != "Childrens":
#		return -1000
	
	#If not on Childrens Block, no more than 3
	var existingShiftIDs = Dictionaries.ShiftTimesPerResident["Shifts"] [resident]
	var numOfChildrens = 0
	for shiftID in existingShiftIDs:
		var shift: String = Dictionaries.AssembledCalendar["Shifts"][shiftID]["ShiftType"]
		if shift.contains("Childrens"):
			numOfChildrens += 1
	
	if numOfChildrens >= 4:
		return -10
	return 3

func notTooManyFFX(resident: String, shiftInfo: Dictionary):
	#if current block is FFX, points
	var currentBlock: String = Dictionaries.ResidentDict[resident]["Block"]
	var newShiftType = shiftInfo["ShiftType"]
	if currentBlock.contains("FFX") and newShiftType.contains("FFX"): return 10
	
	#If block is not FFX, No more than 5 FFX/FFX Peds shifts
	var existingShiftIDs = Dictionaries.ShiftTimesPerResident["Shifts"] [resident]
	var numOfFFX = 0
	for shiftID in existingShiftIDs:
		var shiftType: String = Dictionaries.AssembledCalendar["Shifts"][shiftID]["ShiftType"]
		if shiftType.contains("FFX"):
			numOfFFX += 1
	
	if numOfFFX >= 6:
		return -5
	return 0

func mixtureOfShiftTimes(resident: String, shiftInfo: Dictionary):
	#get which time of day this shift is
	var Hour = shiftInfo["Date"]["hour"]
	var rangeOfHours = [1,10]
	if Hour > 0 and Hour < 10: rangeOfHours = [1,10]
	elif Hour >= 10 and Hour < 18: rangeOfHours = [10,18]
	elif Hour >= 18: rangeOfHours = [18, 25]
	
	#if >=7 of any particular shift time, give -3 points to the shift
	var existingShiftIDs = Dictionaries.ShiftTimesPerResident["Shifts"][resident]
	var similarTimedShifts = 0
	for shiftID in existingShiftIDs:
		var shiftTime = getDateFromShiftID(shiftID)["hour"]
		if shiftTime >= rangeOfHours[0] and shiftTime < rangeOfHours[1]:
			similarTimedShifts += 1
	
	if similarTimedShifts >= 7:
		return -2
	return 0

func daysOffAroundVacationWeek(resident: String, shiftInfo: Dictionary, blockStartDate):
	var shiftDayOfBlock: float = daysBetweenDates(blockStartDate, shiftInfo["Date"])
	var currentWeek: int = floor(shiftDayOfBlock / 7.0) + 1
	var shiftDayOfWeek = getDayOfWeek(shiftInfo["Date"])
	var vacationWeeks = getVacationWeeks(resident)
	var PGY = Dictionaries.ResidentDict[resident]["PGY"]
	
	for week in vacationWeeks:
		if currentWeek == (week - 1) and shiftDayOfWeek == 0:
			return (-1 * PGY)
		if currentWeek == (week + 1) and shiftDayOfBlock == 1:
			return (-1 * PGY)
	return 0

func fewerDOMAs(resident: String, shiftInfo: Dictionary):
	if Dictionaries.ResidentDict[resident]["PGY"] == 1: return 0 #Interns need DOMAs to fit schedule
	#check if morning shift
	var Hour = shiftInfo["Date"]["hour"]
	if Hour < 1 or Hour > 12: return 0
	#check if between 30 and 40 hours before, resident had shift that started => 16
	var newShiftUnixTime = Time.get_unix_time_from_datetime_dict(shiftInfo["Date"])
	var existingShiftIDs = Dictionaries.ShiftTimesPerResident["Shifts"][resident]
	for shiftID in existingShiftIDs:
		var shiftTime = Dictionaries.AssembledCalendar["Shifts"][shiftID]["Time"]
		var shiftUnixTime = Time.get_unix_time_from_datetime_dict(Dictionaries.AssembledCalendar["Shifts"][shiftID]["Date"])
		var timeDiff: float = float(newShiftUnixTime - shiftUnixTime) / float(Constants.UnixHour)
		if shiftTime > 17 and timeDiff > 29 and timeDiff < 41:
			return -2
	return 0

func pointsForInternWednesdayShifts(resident: String, shiftInfo: Dictionary):
	#In order to better fit in all 20 shifts
	var weekday = getDayOfWeek(shiftInfo["Date"])
	if weekday != 3: return 0
	var PGY = Dictionaries.ResidentDict[resident]["PGY"]
	if PGY == 1: return 5
	elif PGY == 2: return 2
	
	return 0

func pointsForOffServiceWedMornings(resident: String, shiftInfo: Dictionary):
	var PGY = Dictionaries.ResidentDict[resident]["PGY"]
	if PGY != 0: return 0
	if getDayOfWeek(shiftInfo["Date"]) != 3: return 0
	
	var timeOfDay = shiftInfo["Date"]["hour"]
	if timeOfDay < 13:
		return 5
	return 0


#------------------ Blocking Functions -----------------------
func blockOffGoldenWeekends(blockStartDate):
	#populate Fri(5), Sat(6), and Sun(0) as days off for Dictionaries.GoldenWeekendDict["DaysOff"][resident]
	var goldenWeekendDict = Dictionaries.GoldenWeekendDict["DaysOff"]
	var Residents = Dictionaries.ResidentDict.keys()
	
	randomize()
	for resident in Residents:
		var PGY = Dictionaries.ResidentDict[resident]["PGY"]
		var weeksOnService = Dictionaries.ResidentDict[resident]["WeeksOn"]
		var vacationWeeks = getVacationWeeks(resident)
		#If Res has Vacation Week, set weekend off right before it, otherwise random
		var weekendNumber = randi_range(1,4)
		if vacationWeeks.is_empty() == false:
			for week in vacationWeeks:
				if week > 1: weekendNumber = (week - 1)
		
		if weeksOnService.size() >= 4 and PGY != 0:
			#figure out what day numbers fri, sat, and sun are
			var weekdayOfBlockStart = getDayOfWeek(blockStartDate)
			var UnixFridayOfBlockStartWeek = Time.get_unix_time_from_datetime_dict(blockStartDate) - ((weekdayOfBlockStart - 5) * Constants.UnixDay)
			var UnixFridayOff = UnixFridayOfBlockStartWeek + ((weekendNumber - 1) * Constants.UnixWeek)
			var UnixSatOff = UnixFridayOff + Constants.UnixDay
			var UnixSunOff = UnixSatOff + Constants.UnixDay
		
			#populate goldenWeekendDict[resident] with those days off
			Dictionaries.GoldenWeekendDict["DaysOff"][resident] = []
			Dictionaries.GoldenWeekendDict["DaysOff"][resident].append(Time.get_date_dict_from_unix_time(UnixFridayOff))
			Dictionaries.GoldenWeekendDict["DaysOff"][resident].append(Time.get_date_dict_from_unix_time(UnixSatOff))
			Dictionaries.GoldenWeekendDict["DaysOff"][resident].append(Time.get_date_dict_from_unix_time(UnixSunOff))
	return


#------------------ Swapping/Adding/Removing Shifts -------------------------
func isValidShift(shiftID, resident: String):
	#purposefully respecting Golden Weekend and Day Off Requests
	var points = calculatePointsForShift(shiftID, resident, pullCurrentBlockStartDate())
	print("points: " + str(points))
	if points > -100:
		return true
	return false

func isValidSwap(shiftOneID: String, shiftTwoID: String, ignoreReqOff = true):
	var tmpShiftDict = Dictionaries.AssembledCalendar["Shifts"].duplicate(true)
	var tmpResShiftTimes = Dictionaries.ShiftTimesPerResident["Shifts"].duplicate(true)
	var shiftOne = {shiftOneID: tmpShiftDict[shiftOneID]}
	var shiftTwo = {shiftTwoID: tmpShiftDict[shiftTwoID]}
	#Get Names of Residents
	var resOne = shiftOne.values()[0]["Resident"]
	var resTwo = shiftTwo.values()[0]["Resident"]
	
	#unfill residents from shiftOne and shiftTwo
	Dictionaries.AssembledCalendar["Shifts"][shiftOne.keys()[0]]["Resident"] = "Unfilled"
	Dictionaries.AssembledCalendar["Shifts"][shiftTwo.keys()[0]]["Resident"] = "Unfilled"
	Dictionaries.ShiftTimesPerResident["Shifts"][resOne].erase(shiftOneID)
	Dictionaries.ShiftTimesPerResident["Shifts"][resTwo].erase(shiftTwoID)
	
	#Disregard requested days off (and Golden Weekend Days)
	var tmpRequestOffDict = Dictionaries.RequestOffDict["DaysOff"].duplicate(true)
	var tmpGoldenWeekendDict = Dictionaries.GoldenWeekendDict["DaysOff"].duplicate(true)
	if ignoreReqOff == true:
		Dictionaries.RequestOffDict["DaysOff"][resOne] = []
		Dictionaries.RequestOffDict["DaysOff"][resTwo] = []
		Dictionaries.GoldenWeekendDict["DaysOff"][resOne] = []
		Dictionaries.GoldenWeekendDict["DaysOff"][resTwo] = []
	
	#Check if residentOne has valid schedule in ShiftTwo and vice versa
	var resOneNewShiftPoints = calculatePointsForShift(shiftTwo.keys()[0], resOne, pullCurrentBlockStartDate())
	var resTwoNewShiftPoints = calculatePointsForShift(shiftOne.keys()[0], resTwo, pullCurrentBlockStartDate())
	#print("Swap points = " + str(resOneNewShiftPoints) + " / " + str(resTwoNewShiftPoints))
	
	#Repopulate AssembledCalendar, ShiftTimes, RequestOff to orginal states (because they were modified above)
	Dictionaries.AssembledCalendar["Shifts"] = tmpShiftDict
	Dictionaries.ShiftTimesPerResident["Shifts"] = tmpResShiftTimes
	Dictionaries.RequestOffDict["DaysOff"] = tmpRequestOffDict
	Dictionaries.GoldenWeekendDict["DaysOff"] = tmpGoldenWeekendDict
	
	if resOneNewShiftPoints > -100 and resTwoNewShiftPoints > -100:
		return true
	return false

func getAllValidSwaps(shiftID):
	var validSwaps = []
	var cal = Dictionaries.AssembledCalendar["Shifts"].duplicate()
	var resident = cal[shiftID]["Resident"]
	if resident == "Unfilled": return []
	
	for othershiftID in cal.keys():
		#prune out 
		var otherRes = getResFromID(othershiftID)
		if resident != otherRes and otherRes != "Unfilled":
		#check is valid swap and add IF to validSwaps array
			var valid = isValidSwap(shiftID, othershiftID)
			if valid == true:
				validSwaps.append(othershiftID)
	return validSwaps

func swapShiftsInDict(shiftOneID: String, shiftTwoID: String):
	#Executes the shift swap within Dictionaries.AssembledCalendar["Shifts"]
	#ONLY USE IF isValidSwap is true
	var tmpShiftDict = Dictionaries.AssembledCalendar["Shifts"].duplicate()
	var shiftOne = {shiftOneID: tmpShiftDict[shiftOneID]}
	var shiftTwo = {shiftTwoID: tmpShiftDict[shiftTwoID]}
	var resOne = shiftOne.values()[0]["Resident"]
	var resTwo = shiftTwo.values()[0]["Resident"]
#	print("res one = " + str(resOne))
	tmpShiftDict[shiftOne.keys()[0]]["Resident"] = resTwo
	tmpShiftDict[shiftTwo.keys()[0]]["Resident"] = resOne
	
	Dictionaries.AssembledCalendar["Shifts"] = tmpShiftDict
	return


#------------------ Meta / Math Functions ---------------------
func evaluateQualityOfSchedule(calendar):
	#Calendar based on assembled calendar
	var points = 0
	var shiftIDs = calendar.keys()
	for shiftID in shiftIDs:
	#Gain points for: 
		#Schedules where more nights are clumped
	#Lose Points for:
		#Unfilled Shifts (More points for unfilled senior shifts and childrens shifts and weekend shifts)
		if calendar[shiftID]["Resident"] == "Unfilled":
			var type = calendar[shiftID]["ShiftType"]
			if type == "GWS":
				points -= 3
			if type == "Childrens":
				points -= 2
			if ["GWD", "GWE"].has(type):
				points -= 1
			if ["GWA", "GWB","GWC","FFX"].has(type):
				points -= 2
			if type == "FFXPeds":
				points += 0
			if [5,6,0].has(getDayOfWeek(calendar[shiftID]["Date"])):
				points -= 1
	return points

func maxNumOfShifts(resident: String):
	var num = 0
	var resInfo = pullInfoAboutResident(resident)
	if resInfo == null: return 0
	var PGY: int = resInfo["PGY"]
	
	if Dictionaries.Chiefs.has(resident): num = 12
	elif PGY == 0: num = 15 #how many shifts for unchecked service residents?
	else: num = 22 - (2 * PGY)
	
	#Adjust Based on Weeks On
	var weeksOn: float = resInfo["WeeksOn"].size()
	num = floor(num * (weeksOn / 4.0))
	return num

func getVacationWeeks(resident: String):
	var weeksOn = Dictionaries.ResidentDict[resident]["WeeksOn"]
	var vacationWeeks = []
	for i in range(1,5):
		if weeksOn.has(i) == false:
			vacationWeeks.append(i)
	return vacationWeeks

func getAllNightShifts():
	var cal = Dictionaries.AssembledCalendar["Shifts"]
	var nightShiftIDs: Array = []
	for shiftID in cal.keys():
		if cal[shiftID]["Date"]["hour"] > 17:
			nightShiftIDs.append(shiftID)
	return nightShiftIDs

func pullInfoAboutResident(resident: String):
	var dict = Dictionaries.ResidentDict
	if dict.has(resident):
		var value = dict[resident]
		return value
	return null

func pullCurrentBlockStartDate(blockNumber = "0"):
	if blockNumber == "0":
		blockNumber = Constants.currentBlock
	var dateTimeString = Dictionaries.CalendarDict[blockNumber]["Start"]
	return Time.get_datetime_dict_from_datetime_string(dateTimeString,false)

func getDateFromShiftID(shiftID):
	return Dictionaries.AssembledCalendar["Shifts"][shiftID]["Date"]

func durationOfShift(shiftID):
	return Dictionaries.AssembledCalendar["Shifts"][shiftID]["Duration"]

func getResFromID(shiftID):
	return Dictionaries.AssembledCalendar["Shifts"][shiftID]["Resident"]
	
