extends Control

@export var item: PackedScene
@export var list: Control

func _ready():
	var wsl = Global.get_wordset_list()
	for ws in wsl:
		var i = item.instantiate()
		i.text = ws
		i.path = wsl[ws]
		i.button_pressed = false
		list.add_child(i)

func delete_wordset(path: String):
	# 1. Check if the file exists
	if FileAccess.file_exists(path):
		# 2. Attempt to remove the file
		var err = DirAccess.remove_absolute(path)
		
		if err == OK:
			print("File deleted successfully: " + path)
			
			# 3. Remove it from your Global dictionary so the game stops looking for it
			if Global.wordsets.has(path):
				Global.wordsets.erase(path)
				
			return true
		else:
			print("Error: Could not delete file. Error code: " + str(err))
			return false
	else:
		print("Error: File does not exist at " + path)
		return false

func _on_done_pressed():
	for child in list.get_children():
		if child.button_pressed: 
			delete_wordset(child.path)
			
	# Only change scene if at least one wordset is enabled
	get_tree().change_scene_to_file("res://scenes/words.tscn")

func _on_cancel_pressed():
	get_tree().change_scene_to_file("res://scenes/add_word_set.tscn")
