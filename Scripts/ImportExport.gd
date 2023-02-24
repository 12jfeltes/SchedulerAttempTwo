extends Node


func _ready():
	pass

func importCSVCalendar(dir = null):
	var dict = {}
	var folderPath  = "" #"user://savedCalendars.dat"
	var file = FileAccess.open(folderPath, FileAccess.READ)
	if file == null: return dict
	while !file.eof_reached():
		var dataSet = Array(file.get_csv_line())
		dict[dict.size()] = dataSet
	return dict

#func convertDictToCSV()
	#To take existing calendar and export as CSV to then download

#func downloadCSVCalendar(dir = null):
#	#Step 1. Convert Calendar to PackedStringArray
#	var cal = {"Key 1": "Value 1",
#				"Key 2": "Value 2"}
#
#
#	#Step 2: Download CSV to cache and then load as bytearray
#	var folderPath  = "user://downloadedCal.dat"
#	var file = FileAccess.open(folderPath, FileAccess.WRITE)
#	file.store_var()
##	file.store_csv_line()
#	var uploadedFile = "123"
#	#Step 3: Re-download, now as a functional ByteArray
#	if OS.has_feature("web"):
#		JavaScriptBridge.download_buffer(uploadedFile.to_utf8_buffer(), "calendar.csv", "text/csv")
#			#text.to_utf8(), "file.txt", "text")
#	return


