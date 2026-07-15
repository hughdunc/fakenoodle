extends Control

func _ready():
	var imposters: Array = []
	for i in Global.imposter_indexes:
		imposters.append(Global.players[i])
	$Button/VBoxContainer/Player.text = ", ".join(imposters)
	$Button/VBoxContainer/Word.text = "Word: " + Global.word
	$Button/VBoxContainer/Hint.text = "Hint: " + Global.hint


func _on_done_pressed():
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
