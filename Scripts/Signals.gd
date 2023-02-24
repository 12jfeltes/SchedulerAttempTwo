extends Node

signal filterCalendar()
	#Also a refresh calendar signal
	#emitted from FilterButton to reload calendar with resident filter
	#also emitted by Assign Shift Popup to refresh calendar

signal swapShifts()
	#emitted when SwapShift.tscn button is pressed
	#Picked up by ShiftCalendar.gd

signal popUpMessage(text: String)
	#Emitted from any Node
	#Picked up by PopUpMessage.tscn to display message

signal saveCalendar()
	#Emitted by SaveCalendarButton.tscn
	#Picked up by Dictionaries

signal openAssignShiftPanel(shiftID)
	#Emitted by AssignUnasign.tscn
	#Picked Up by the Assign Shift Panel

signal openAddRemoveShiftPanel(shiftID)
	#Emitted from AddShift Button
	#Picked up by Add Remove Shift Panel .tscn

signal showPossibleTrades()
	#Emitted from top toolbar button
	#picked up by shiftcalendar.tscn
