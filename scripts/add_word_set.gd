extends Control

# --- NAVIGATION FUNCTIONS ---

func _on_create_pressed():
	get_tree().change_scene_to_file("res://scenes/create_wordset.tscn")

func _on_paste_pressed():
	get_tree().change_scene_to_file("res://scenes/paste_wordset.tscn")

func _on_export_pressed():
	get_tree().change_scene_to_file("res://scenes/export_wordsets.tscn")

func _on_find_pressed():
	print("I dont have this set up yet so fuck you")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/words.tscn")

func _on_delete_pressed():
	get_tree().change_scene_to_file("res://scenes/delete_wordset.tscn")

# --- IMPORT FUNCTIONS ---

func _on_import_pressed():
	# Trigger the native OS File Picker with multi-select enabled (true)
	DisplayServer.file_dialog_show(
		"Select JSON Wordset(s)", 
		"", 
		"", 
		true, # ALLOW MULTIPLE SELECTION = true
		DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, 
		["*.json"], 
		_on_file_selected
	)

# Callback function executed when the user picks files
func _on_file_selected(status: bool, selected_paths: PackedStringArray, _selected_filter_index: int):
	if status and selected_paths.size() > 0:
		var successful_imports = 0
		
		# Loop through every path selected by the user
		for path in selected_paths:
			if import_single_file(path):
				successful_imports += 1
		
		if successful_imports > 0:
			print("Import Successful! Imported " + str(successful_imports) + " files.")
			# Refresh the Global dictionary so the game detects the new files
			Global.load_wordsets_from_folder() 
			get_tree().change_scene_to_file("res://scenes/words.tscn")
		else:
			print("No valid files were imported.")

# Logic to check and import a SINGLE file
func import_single_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false

	var json_string = FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(json_string)

	# Validation: Check if it has a name, "words" dictionary, and at least one word
	var is_valid = false
	if data is Dictionary:
		if data.has("name") and data.has("words") and typeof(data["words"]) == TYPE_DICTIONARY:
			if data["words"].size() >= 1:
				is_valid = true

	if is_valid:
		# Copy the file to our local user directory
		var filename = path.get_file()
		var destination = "user://wordsets/" + filename
		
		# Ensure directory exists
		var dir = DirAccess.open("user://wordsets/")
		if not dir:
			DirAccess.make_dir_recursive_absolute("user://wordsets/")
		
		# Perform the copy
		var source_file = FileAccess.open(path, FileAccess.READ)
		var dest_file = FileAccess.open(destination, FileAccess.WRITE)
		
		if source_file and dest_file:
			dest_file.store_string(source_file.get_as_text())
			source_file.close()
			dest_file.close()
			return true
	
	print("Error: File " + path + " is invalid or could not be copied.")
	return false
