extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(delta):
	pass


func _on_button_pressed():
	#TODO: Open up confirmation dialogue and await signal back
	Signals.emit_signal("saveCalendar")
	Signals.emit_signal("popUpMessage", "Calendar Saved!")
	pass 
