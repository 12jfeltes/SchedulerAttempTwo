extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$SpinBox.value = int(Constants.currentBlock)
	pass


func _on_spin_box_value_changed(value):
	Constants.currentBlock = str(value)
	pass
