extends HBoxContainer

signal up_pressed(item)
signal down_pressed(item)
signal remove_pressed(item)



func _on_up_pressed():
	up_pressed.emit(self)


func _on_down_pressed():
	down_pressed.emit(self)


func _on_remove_pressed():
	remove_pressed.emit(self)
