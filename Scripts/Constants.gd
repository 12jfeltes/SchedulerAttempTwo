extends Node

const UnixHour = 3600

const UnixDay = 86400

const UnixWeek = 604800

var selectedResident = null
	#assigned when you filter calendar by one (or more) residents

var currentBlock = "1"

var loadExistingSchedule = false
	#Assigned true when load button hit on Selection Screen
