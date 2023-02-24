extends Node

func _ready():
	loadCalendars()
	Signals.connect("saveCalendar", saveCalendar)
	#Programatically Populate empty Dictionaries
	#1. ShiftTimesPerResident Dict (filling in resident names)
	#2. RequestOff Dict - eventually need to fill these in by hand
	#3. BackUp Call Dict - eventually need to fill these in by hand
	for resident in ResidentDict.keys():
		ShiftTimesPerResident["Shifts"][resident] = []
		RequestOffDict["DaysOff"][resident] = []
		BackupCallDict["Backup"][resident] = []
	pass

func clearDictionaries():
	AssembledCalendar["Shifts"] = {}
	ShiftTimesPerResident["Shifts"] = {}
	
	#Re-populate template for erased dictionaries
	for resident in ResidentDict.keys():
		ShiftTimesPerResident["Shifts"][resident] = []
	return

func populateShiftsPerResidentDict():
	#from Assembled Calendar.
	#Used from SelectionScreen when loading saved data
	#1. Clear Dict
	ShiftTimesPerResident["Shifts"] = {}
	
	#fill empty template
	for resident in ResidentDict.keys():
		ShiftTimesPerResident["Shifts"][resident] = []
	var cal = AssembledCalendar["Shifts"].duplicate()
	var resCal = ShiftTimesPerResident["Shifts"].duplicate()
	
	#add assembledshifts
	for shiftID in cal.keys():
		var resident = cal[shiftID]["Resident"]
		if resident != null and resident != "Unfilled":
			resCal[resident].append(shiftID)
	
	ShiftTimesPerResident["Shifts"] = resCal
	return

func saveCalendar():
	#signaled when you hit SaveaCalendarButton.tscn
	#get calendar data
	var currentBlock = Constants.currentBlock
	var blockData = AssembledCalendar["Shifts"].duplicate()
	savedCalendars["Calendars"][currentBlock] = blockData
	
	var folderPath  = "user://savedCalendars.dat"
	var file = FileAccess.open(folderPath, FileAccess.WRITE)
	file.store_var(savedCalendars,false)
	
	print("Block " + str(currentBlock) + " Calendar Saved")
	return

func loadCalendars():
	var folderPath  = "user://savedCalendars.dat"
	var file = FileAccess.open(folderPath, FileAccess.READ)
	var content = savedCalendars
	if file != null:
		content = file.get_var()
	savedCalendars = content
	return content

func resetAllCalendars():
	savedCalendars["Calendars"] = {}
	var folderPath  = "user://savedCalendars.dat"
	var file = FileAccess.open(folderPath, FileAccess.WRITE)
	file.store_var(savedCalendars,false)
	return

#---------------------- Constants -----------------------

const defaultStartingDate = {"day":23, "month":11, "year":2022}

#Calendar
const CalendarDict = { #for the dates of each block
	"1": {"Start": "2023-07-01", "End": "2023-07-30", "Days": 30},
	"2": {"Start": "2023-07-31", "End": "2023-08-27", "Days": 28},
	"3": {"Start": "2023-08-28", "End": "2023-09-24", "Days": 28},
	"4": {"Start": "2023-09-25", "End": "2023-10-22", "Days": 28},
	"5": {"Start": "2023-10-23", "End": "2023-11-19", "Days": 28},
	"6": {"Start": "2023-11-20", "End": "2023-12-17", "Days": 28},
	"7": {"Start": "2023-12-18", "End": "2024-01-14", "Days": 28},
	"8": {"Start": "2024-01-15", "End": "2024-02-11", "Days": 28},
	"9": {"Start": "2024-02-12", "End": "2024-03-10", "Days": 28},
	"10": {"Start": "2024-03-11", "End": "2024-04-07", "Days": 28},
	"11": {"Start": "2024-04-08", "End": "2024-05-05", "Days": 28},
	"12": {"Start": "2024-05-06", "End": "2024-06-02", "Days": 28},
	"13": {"Start": "2024-06-03", "End": "2024-06-30", "Days": 28},
}

#Shift Requirements
const ShiftReqDict = {
	"GWA": {"PGY": [2,3,4]},
	"GWB": {"PGY": [1,2,3,4]},
	"GWC": {"PGY": [0,1,2,3,4]},
	"GWD": {"PGY": [0,1,2,3,4]},
	"GWE": {"PGY": [0,1,2,3,4]},
	"GWS": {"PGY": [4]},
	"GWProc": {"PGY": [1]}, #doesn't really matter b/c only 1 proc resident at any given time
	"FFX": {"PGY": [1,2,3,4]}, #FFX: Only PGY1-4 if finished FFX block
	"FFXPeds": {"PGY": [2,3,4]}, #(templated shifts?)
	"Childrens": {"PGY": [1,2,3]}, #if finished Childrens
}

const ShiftTimesDict = {
	"GWA": {
		"GWA-WeekdayM": {"Start": 6, "Duration": 8},
		"GWA-WeekdayE": {"Start": 14, "Duration": 8},
		"GWA-WeekdayN": {"Start": 22, "Duration": 8},
		"GWA-WeekendM": {"Start": 6, "Duration": 12},
		"GWA-WeekendN": {"Start": 18, "Duration": 12},
	},
	#TODO: GWB templates
	"GWB": {
		"GWB-M": {"Start": 7, "Duration": 12},
		"GWB-N": {"Start": 19, "Duration": 12},
	},
	"GWC": {
		"GWC-WeekdayM": {"Start": 8, "Duration": 8},
		"GWC-WeekdayE": {"Start": 16, "Duration": 8},
		"GWC-WeekdayN": {"Start": 24, "Duration": 8},
		"GWC-TuesdayE": {"Start": 16, "Duration": 7},
		"GWC-TuesdayN": {"Start": 23, "Duration": 9},
		"GWC-WeekendM": {"Start": 8, "Duration": 12},
		"GWC-WeekendN": {"Start": 20, "Duration": 12},
	},
	"GWD": {
		"GWD-WeekdayM": {"Start": 9, "Duration": 8},
		"GWD-WeekdayE": {"Start": 17, "Duration": 8},
		"GWD-WeekdayN": {"Start": 23, "Duration": 9},
	},
	"GWE": {
		"GWE-WeekdayM": {"Start": 9, "Duration": 8},
		"GWE-WeekdayE": {"Start": 17, "Duration": 8},
		"GWE-WeekendE": {"Start": 14, "Duration": 8},
	},
	"GWS": {
		"GWS-WeekdayM": {"Start": 7, "Duration": 8},
		"GWS-WeekdayE": {"Start": 15, "Duration": 8},
		"GWS-WeekdayN": {"Start": 23, "Duration": 8},
		"GWS-WeekendM": {"Start": 7, "Duration": 12},
		"GWS-WeekendN": {"Start": 19, "Duration": 12},
	},
	"FFX": {
		"FFX-WeekdayM": {"Start": 6, "Duration": 8},
		"FFX-WeekdayE": {"Start": 14, "Duration": 8},
		"FFX-WeekdayN": {"Start": 22, "Duration": 8},
		"FFX-WeekendM": {"Start": 6, "Duration": 12},
		"FFX-WeekendN": {"Start": 18, "Duration": 12},
	},
	"FFXPeds": {
		"FFXPeds-M": {"Start": 6, "Duration": 10},
		"FFXPeds-E": {"Start": 15, "Duration": 10},
		"FFXPeds-N": {"Start": 22, "Duration": 10},
		#More?
	},
	"Childrens": {
		"Childrens-M": {"Start": 7, "Duration": 10},
		"Childrens-E": {"Start": 13, "Duration": 10},
		"Childrens-N": {"Start": 22, "Duration": 10},
	},
	"GWProc": {
		#TODO: GWProc shifts
	},
	"VA": {
		#TODO. Usually 7a-3p or 3p-11p M-F
		#Also less frequently 10a-8p Sat and Sun
	},
	"TR": {
		"Teaching-Shift": {"Start": 9, "Duration": 8},
	},
}

const ShiftsAvailableDict = { # 0 = Sunday, 6 = Saturday
	1: #Monday
				{"GWA": ["GWA-WeekdayM", "GWA-WeekdayE", "GWA-WeekdayN"],
				"GWC": ["GWC-WeekdayM", "GWC-WeekdayE", "GWC-WeekdayN"],
				"GWD": ["GWD-WeekdayM", "GWD-WeekdayE", "GWD-WeekdayN"],
				"GWE": ["GWE-WeekdayE"],
				"GWS": ["GWS-WeekdayM", "GWS-WeekdayE", "GWS-WeekdayN"],
				"FFX": ["FFX-WeekdayM", "FFX-WeekdayE", "FFX-WeekdayN"],
				"FFXPeds": ["FFXPeds-M"],
				"Childrens": ["Childrens-E"],
				},
	2: #Tuesday
				{"GWA": ["GWA-WeekdayM", "GWA-WeekdayE", "GWA-WeekdayN"],
				"GWC": ["GWC-WeekdayM", "GWC-TuesdayE", "GWC-TuesdayN"],
				"GWD": ["GWD-WeekdayM", "GWD-WeekdayE", "GWD-WeekdayN"],
				"GWE": ["GWE-WeekdayE"],
				"GWS": ["GWS-WeekdayM", "GWS-WeekdayE"],
				"FFX": ["FFX-WeekdayM", "FFX-WeekdayE"],
				"FFXPeds": ["FFXPeds-M"],
				"Childrens": ["Childrens-M"],
				},
	3: #Wednesday
				{"GWA": ["GWA-WeekdayM", "GWA-WeekdayE", "GWA-WeekdayN"],
				"GWC": ["GWC-WeekdayM", "GWC-WeekdayE", "GWC-WeekdayN"],
				"GWD": ["GWD-WeekdayM", "GWD-WeekdayE"],
				"GWE": ["GWE-WeekdayE"],
				"GWS": ["GWS-WeekdayE", "GWS-WeekdayN"],
				"FFX": ["FFX-WeekdayE", "FFX-WeekdayN"],
				"Childrens": ["Childrens-N"],
				},
	4: #Thursday
				{"GWA": ["GWA-WeekdayM", "GWA-WeekdayE", "GWA-WeekdayN"],
				"GWC": ["GWC-WeekdayM", "GWC-WeekdayE", "GWC-WeekdayN"],
				"GWD": ["GWD-WeekdayM", "GWD-WeekdayE"],
				"GWE": ["GWE-WeekdayE"],
				"GWS": ["GWS-WeekdayM", "GWS-WeekdayE", "GWS-WeekdayN"],
				"FFX": ["FFX-WeekdayM", "FFX-WeekdayE", "FFX-WeekdayN"],
				"FFXPeds": ["FFXPeds-M"],
				"Childrens": ["Childrens-N"],
				},
	5: #Friday
				{"GWA": ["GWA-WeekdayM", "GWA-WeekdayE", "GWA-WeekdayN"],
				"GWB": ["GWB-N"],
				"GWC": ["GWC-WeekdayM", "GWC-WeekdayE", "GWC-WeekdayN"],
				"GWD": ["GWD-WeekdayM", "GWD-WeekdayE"],
				"GWE": ["GWE-WeekdayE"],
				"GWS": ["GWS-WeekdayM", "GWS-WeekdayE", "GWS-WeekdayN"],
				"FFX": ["FFX-WeekdayM", "FFX-WeekdayE", "FFX-WeekdayN"],
				"FFXPeds": ["FFXPeds-M"],
				"Childrens": ["Childrens-N"],
				},
	6: #Saturday
				{"GWA": ["GWA-WeekendM", "GWA-WeekendN"],
				"GWB": ["GWB-M", "GWB-N"],
				"GWC": ["GWC-WeekendM", "GWC-WeekendN"],
				"GWE": ["GWE-WeekendE"],
				"GWS": ["GWS-WeekendM", "GWS-WeekendN"],
				"FFX": ["FFX-WeekendM", "FFX-WeekendN"],
				},
	0: #Sunday
				{"GWA": ["GWA-WeekendM", "GWA-WeekendN"],
				"GWB": ["GWB-M", "GWB-N"],
				"GWC": ["GWC-WeekendM", "GWC-WeekendN"],
				"GWE": ["GWE-WeekendE"],
				"GWS": ["GWS-WeekendM", "GWS-WeekendN"],
				"FFX": ["FFX-WeekendM", "FFX-WeekendN"],
				"Childrens": ["Childrens-N"],
				},
	#TODO: figure out which FFXPeds templated shifts we do
}

var AllResidents = { #UNUSED
	"Residents": {
		#Master Schedule for Every resident in the program.
		#TODO: Should have schedule by WEEK in Weeks as array within dictionary organized by block 
		"Amelia Bryan": {"PGY": 1, "Vacation": [], "Weeks": {}, "Call Days": []},
		"Pierce Campbell": {"PGY": 1, "Vacation": [], "Weeks": {}, "Call Days": []},
		"Jordan Detrick": {"PGY": 1, "Vacation": [], "Weeks": {}, "Call Days": []},
		"Leslie Gailloud": {"PGY": 1, "Vacation": [], "Weeks": {}, "Call Days": []},
		"Victoria Larsen": {"PGY": 1, "Vacation": [], "Weeks": {}, "Call Days": []},
		"Catherine Levitt": {"PGY": 1, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Jennifer Luk": {"PGY": 1, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Katherine Markin": {"PGY": 1, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Lauren Rosenfeld": {"PGY": 1, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Melanie Schroeder": {"PGY": 1, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Caitlin Williams": {"PGY": 1, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Kirsten Boone": {"PGY": 2, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Karen Chung": {"PGY": 2, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Hannah Fairley": {"PGY": 2, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Timothy Harmon": {"PGY": 2, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Arman Hussain": {"PGY": 2, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Robert Pena": {"PGY": 2, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Taylor Peter-Bibb": {"PGY": 2, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Kathryn Thompson": {"PGY": 2, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "FFX", "PrevRotGW": false, "NextRot": false},
		"Samuel Winsten": {"PGY": 2, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "FFX", "PrevRotGW": false, "NextRot": false},
		"Uthman Alamoudi": {"PGY": 3, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Jordan Feltes": {"PGY": 3, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Ian Hunter": {"PGY": 3, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Yasir Hussein": {"PGY": 3, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Owen Lee Park": {"PGY": 3, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Ashleigh Omorogbe": {"PGY": 3, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"John Organick-Lee": {"PGY": 3, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Elizabeth Rempfer": {"PGY": 3, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Andrew Singletary": {"PGY": 3, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Ryan Skrabal": {"PGY": 3, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Angela Wu": {"PGY": 3, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "FFX", "PrevRotGW": false, "NextRot": false},
		"Fatmah Alsomali": {"PGY": 4, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Joseph Brooks": {"PGY": 4, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Brandon Chaffay": {"PGY": 4, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Alexander Kreisman": {"PGY": 4, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Joel Lange": {"PGY": 4, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Malori Lankenau": {"PGY": 4, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Ayal Pierce": {"PGY": 4, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Margarita Popova": {"PGY": 4, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Kristin Raphel": {"PGY": 4, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
		"Michael West": {"PGY": 4, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "FFX", "PrevRotGW": false, "NextRot": false},
		"OffService1": {"PGY": 0, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": true, "NextRot": true},
		"OffService2": {"PGY": 0, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": true, "NextRot": true},
		"OffService3": {"PGY": 0, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": true, "NextRot": true},
		"OffService4": {"PGY": 0, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": true, "NextRot": true},
		"OffService5": {"PGY": 0, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": true, "NextRot": true},
		"OffService6": {"PGY": 0, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": true, "NextRot": true},
		"OffService7": {"PGY": 0, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": true, "NextRot": true},
	}
}

#Resident Dict
var ResidentDict = {
	"Amelia Bryan": {"PGY": 1, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
	"Pierce Campbell": {"PGY": 1, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
	"Jordan Detrick": {"PGY": 1, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
	"Leslie Gailloud": {"PGY": 1, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "FFX", "PrevRotGW": false, "NextRot": false},
#	"Victoria Larsen": {"PGY": 1, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
#	"Catherine Levitt": {"PGY": 1, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
#	"Jennifer Luk": {"PGY": 1, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
#	"Katherine Markin": {"PGY": 1, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
#	"Lauren Rosenfeld": {"PGY": 1, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
#	"Melanie Schroeder": {"PGY": 1, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
#	"Caitlin Williams": {"PGY": 1, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
#	"Kirsten Boone": {"PGY": 2, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
#	"Karen Chung": {"PGY": 2, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
	"Hannah Fairley": {"PGY": 2, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
	"Timothy Harmon": {"PGY": 2, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
	"Arman Hussain": {"PGY": 2, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
	"Robert Pena": {"PGY": 2, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
	"Taylor Peter-Bibb": {"PGY": 2, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
	"Kathryn Thompson": {"PGY": 2, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "FFX", "PrevRotGW": false, "NextRot": false},
	"Samuel Winsten": {"PGY": 2, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "FFX", "PrevRotGW": false, "NextRot": false},
#	"Uthman Alamoudi": {"PGY": 3, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
#	"Jordan Feltes": {"PGY": 3, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
#	"Ian Hunter": {"PGY": 3, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
#	"Yasir Hussein": {"PGY": 3, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
#	"Owen Lee Park": {"PGY": 3, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
#	"Ashleigh Omorogbe": {"PGY": 3, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
	"John Organick-Lee": {"PGY": 3, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
	"Elizabeth Rempfer": {"PGY": 3, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
	"Andrew Singletary": {"PGY": 3, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
	"Ryan Skrabal": {"PGY": 3, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
	"Angela Wu": {"PGY": 3, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "FFX", "PrevRotGW": false, "NextRot": false},
#	"Fatmah Alsomali": {"PGY": 4, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
#	"Joseph Brooks": {"PGY": 4, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
	"Brandon Chaffay": {"PGY": 4, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
	"Alexander Kreisman": {"PGY": 4, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
	"Joel Lange": {"PGY": 4, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
	"Malori Lankenau": {"PGY": 4, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
	"Ayal Pierce": {"PGY": 4, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
	"Margarita Popova": {"PGY": 4, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
	"Kristin Raphel": {"PGY": 4, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": false, "NextRot": false},
	"Michael West": {"PGY": 4, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "FFX", "PrevRotGW": false, "NextRot": false},
	"OffService1": {"PGY": 0, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": true, "NextRot": true},
	"OffService2": {"PGY": 0, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": true, "NextRot": true},
#	"OffService3": {"PGY": 0, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": true, "NextRot": true},
#	"OffService4": {"PGY": 0, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": true, "NextRot": true},
#	"OffService5": {"PGY": 0, "WeeksOn": [1,2,3,4], "Vacation": [], "Block": "GW", "PrevRotGW": true, "NextRot": true},
}

const Chiefs = ["ResPGY4-1", "ResPGY4-2", "ResPGY4-3",]


var AssembledCalendar = {
	"Shifts": {
		"Shift1": {"Date": {"Dict": "ionary"}, "Time": 6, "Duration": 8, "ShiftType": "GWC",
				"ShiftName": "GWC-WeekdayM", "Resident": "Unfilled"}
	}
}

var ShiftTimesPerResident = { #_ready() populates this with same resident names as Resident Dict
	"Shifts": {
#		"ResidentName": [shiftID#1, shiftID#2],
#		"OffService1": []
	}
}

var RequestOffDict = {
	"DaysOff": {}
#	"Name": ["dates"],
}

var BackupCallDict = {
	"Backup": {}
		#"Name": ["dates"]
}

var GoldenWeekendDict = {
	"DaysOff": {}
}

var HolidayDict = {
	#for making shifts weekend schedule instead of weekday
}

var savedCalendars: Dictionary = {
	"Calendars": {
		# BlockNumber : {AssembledCalendar["Shifts"]}
	}
}
