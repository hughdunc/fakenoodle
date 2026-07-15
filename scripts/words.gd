extends Control

@export var item: PackedScene
@export var list: Control

func _ready():
	var wsl = Global.get_wordset_list()
	for ws in wsl:
		var i = item.instantiate()
		i.text = ws
		i.path = wsl[ws]
		# Check if the wordset is in Global and enabled
		i.button_pressed = Global.wordsets.get(wsl[ws], true)
		list.add_child(i)

func _on_done_pressed():
	var i = 0
	
	for child in list.get_children():
		# 1. Update the Global state
		Global.wordsets[child.path] = child.button_pressed
		
		# 2. Write the "enabled" change to the actual JSON file
		if FileAccess.file_exists(child.path):
			# Load the current file data
			var json_string = FileAccess.get_file_as_string(child.path)
			var json_data = JSON.parse_string(json_string)
			
			# Ensure it's a valid dictionary before modifying
			if json_data is Dictionary:
				json_data["enabled"] = child.button_pressed
				
				# Save the updated data back to the file
				var file = FileAccess.open(child.path, FileAccess.WRITE)
				if file:
					file.store_string(JSON.stringify(json_data))
					file.close()
		
		if child.button_pressed: 
			i += 1
			
	# Only change scene if at least one wordset is enabled
	if i >= 1:
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _on_cancel_pressed():
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _on_add_word_set_pressed():
	get_tree().change_scene_to_file("res://scenes/add_word_set.tscn")
