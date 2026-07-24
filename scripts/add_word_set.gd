extends Control

# --- NAVIGATION FUNCTIONS ---

func _on_create_pressed():
	get_tree().change_scene_to_file("res://scenes/create_wordset.tscn")

func _on_paste_pressed():
	get_tree().change_scene_to_file("res://scenes/paste_wordset.tscn")

func _on_export_pressed():
	get_tree().change_scene_to_file("res://scenes/export_wordsets.tscn")

func _on_find_pressed():
	OS.shell_open("https://github.com/hughdunc/fakenoodle/tree/wordsets")

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
		true,
		DisplayServer.FILE_DIALOG_MODE_OPEN_FILES, 
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


func _on_import_zip_pressed():
	DisplayServer.file_dialog_show(
		"Select ZIP Wordset Pack",
		"",
		"",
		false,
		DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
		["*.zip"],
		_on_zip_file_selected
	)

func _on_zip_file_selected(status: bool, selected_paths: PackedStringArray, _selected_filter_index: int):
	if not status or selected_paths.is_empty():
		return

	var zip_path = selected_paths[0]
	if not FileAccess.file_exists(zip_path):
		print("Error: ZIP file does not exist: " + zip_path)
		return

	var temp_root = "user://tmp_zip_import_" + str(int(Time.get_unix_time_from_system()))
	DirAccess.make_dir_recursive_absolute(temp_root)

	var extracted_count = _extract_zip_to_temp(zip_path, temp_root)
	if extracted_count <= 0:
		print("No files extracted from ZIP.")
		_remove_dir_recursive(temp_root)
		return

	var json_paths: Array = []
	_collect_json_files_recursive(temp_root, json_paths)

	var successful_imports = 0
	for json_path in json_paths:
		if import_single_file(json_path):
			successful_imports += 1

	_remove_dir_recursive(temp_root)

	if successful_imports > 0:
		print("ZIP Import Successful! Imported " + str(successful_imports) + " files.")
		Global.load_wordsets_from_folder()
		get_tree().change_scene_to_file("res://scenes/words.tscn")
	else:
		print("No valid JSON wordsets found in ZIP.")

func _extract_zip_to_temp(zip_path: String, temp_root: String) -> int:
	var zip_reader = ZIPReader.new()
	var open_error = zip_reader.open(zip_path)
	if open_error != OK:
		print("Error opening ZIP: " + zip_path + " error=" + str(open_error))
		return 0

	var extracted_count = 0
	for internal_path in zip_reader.get_files():
		var normalized_path = internal_path.replace("\\", "/")
		if normalized_path.ends_with("/"):
			DirAccess.make_dir_recursive_absolute(temp_root.path_join(normalized_path))
			continue

		var output_path = temp_root.path_join(normalized_path)
		var parent_dir = output_path.get_base_dir()
		if parent_dir != "":
			DirAccess.make_dir_recursive_absolute(parent_dir)

		var buffer = zip_reader.read_file(internal_path)
		var out_file = FileAccess.open(output_path, FileAccess.WRITE)
		if out_file:
			out_file.store_buffer(buffer)
			out_file.close()
			extracted_count += 1

	zip_reader.close()
	return extracted_count

func _collect_json_files_recursive(folder: String, out_paths: Array):
	var dir = DirAccess.open(folder)
	if not dir:
		return

	dir.list_dir_begin()
	var entry = dir.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			var full_path = folder.path_join(entry)
			if dir.current_is_dir():
				_collect_json_files_recursive(full_path, out_paths)
			elif entry.to_lower().ends_with(".json"):
				out_paths.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()

func _remove_dir_recursive(folder: String):
	var dir = DirAccess.open(folder)
	if not dir:
		return

	dir.list_dir_begin()
	var entry = dir.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			var full_path = folder.path_join(entry)
			if dir.current_is_dir():
				_remove_dir_recursive(full_path)
			else:
				DirAccess.remove_absolute(full_path)
		entry = dir.get_next()
	dir.list_dir_end()

	DirAccess.remove_absolute(folder)


func _on_change_groups_pressed():
	get_tree().change_scene_to_file("res://scenes/change_wordsets_groups.tscn")
