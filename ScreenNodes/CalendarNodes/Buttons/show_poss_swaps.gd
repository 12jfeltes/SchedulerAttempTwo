extends Button


func _ready():
	pass


func _on_pressed():
	Signals.emit_signal("showPossibleTrades")
	pass
