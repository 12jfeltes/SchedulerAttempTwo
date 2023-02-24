extends Control


func _ready():
	pass # Replace with function body.


func _on_button_pressed():
	Signals.emit_signal("swapShifts")
	pass
