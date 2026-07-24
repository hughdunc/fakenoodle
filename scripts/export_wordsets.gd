extends Control

@export var item: PackedScene
@export var list: Control
@export var word_group: Control
@export var group_list: Control

# We need this to remember which files to export while the file picker is open
var pending_export_paths: Array = []
var wordset_buttons: Dictionary = {}
var select_all_button: Button

func _ready():
	if list:
		list.visible = true
	if word_group:
		select_all_button = word_group.get_node_or_null("Select All")
		word_group.visible = false
	_populate_wordsets()

func _populate_wordsets():
	if not list:
		return

	_clear_container(list)
	wordset_buttons.clear()

	var grouped_entries: Dictionary = {}
	var ungrouped_entries: Array = []
	var wsl = Global.get_wordset_list()

	for ws_name in wsl:
		var path = wsl[ws_name]
		var group_id = _get_group_id(path)
		var entry = {
			"name": ws_name,
			"path": path,
			"group_id": group_id
		}

		if group_id != "":
			if not grouped_entries.has(group_id):
				grouped_entries[group_id] = []
			grouped_entries[group_id].append(entry)
		else:
			ungrouped_entries.append(entry)

	for group_id in grouped_entries.keys().duplicate():
		if grouped_entries[group_id].size() < 2:
			for entry in grouped_entries[group_id]:
				ungrouped_entries.append(entry)
			grouped_entries.erase(group_id)

	var ordered_group_ids = grouped_entries.keys()
	ordered_group_ids.sort_custom(func(a, b):
		return _get_group_label(a) < _get_group_label(b)
	)

	for group_id in ordered_group_ids:
		var group_button = load("res://scenes/word_group.tscn").instantiate()
		group_button.text = _get_group_label(group_id)
		group_button.pressed.connect(_on_group_pressed.bind(grouped_entries[group_id]))
		list.add_child(group_button)

	ungrouped_entries.sort_custom(func(a, b):
		return a["name"].to_lower() < b["name"].to_lower()
	)

	for entry in ungrouped_entries:
		_add_wordset_button(entry, list)

func _add_wordset_button(entry: Dictionary, target: Control):
	var i = item.instantiate()
	i.text = entry["name"]
	i.path = entry["path"]
	i.button_pressed = false
	i.toggled.connect(_on_wordset_toggled.bind(i))
	target.add_child(i)
	wordset_buttons[entry["path"]] = i

func _get_group_id(path: String) -> String:
	if FileAccess.file_exists(path):
		var json_string = FileAccess.get_file_as_string(path)
		var json_data = JSON.parse_string(json_string)
		if json_data is Dictionary:
			var raw_group = null
			if json_data.has("group_id"):
				raw_group = json_data["group_id"]
			elif json_data.has("group"):
				raw_group = json_data["group"]

			if raw_group is String and raw_group.strip_edges() != "":
				return raw_group
	return ""

func _get_group_label(group_id: String) -> String:
	if group_id == null:
		return ""
	var label = str(group_id)
	label = label.replace("_", " ").replace("-", " ")
	label = label.replace(".", " ")
	var regex = RegEx.new()
	regex.compile("[^a-zA-Z0-9]+")
	label = regex.sub(label, " ", true)
	label = label.strip_edges()
	if label == "":
		return ""
	var pieces = label.split(" ", false)
	var readable = ""
	for piece in pieces:
		if piece.is_empty():
			continue
		readable += piece.substr(0, 1).to_upper() + piece.substr(1).to_lower() + " "
	return readable.strip_edges()

func _on_group_pressed(entries: Array):
	if list:
		list.visible = false
	if word_group:
		word_group.visible = true
	_populate_group_items(entries)

func _populate_group_items(entries: Array):
	var target = _get_group_target_container()
	_clear_container(target)
	for entry in entries:
		_add_wordset_button(entry, target)
	_update_select_all_button_text()

func _get_group_target_container() -> Node:
	if group_list and group_list.has_node("Group List"):
		return group_list.get_node("Group List")
	return group_list

func _clear_container(container: Node):
	if not container:
		return
	for child in container.get_children():
		child.queue_free()

func _get_group_checkbuttons() -> Array:
	var buttons: Array = []
	if not group_list:
		return buttons
	for child in group_list.get_children():
		if child is CheckButton:
			buttons.append(child)
	return buttons

func _update_select_all_button_text():
	if not select_all_button:
		return

	var buttons = _get_group_checkbuttons()
	if buttons.is_empty():
		select_all_button.text = "Select All"
		return

	var all_selected = true
	for button in buttons:
		if not button.button_pressed:
			all_selected = false
			break

	select_all_button.text = "Deselect All" if all_selected else "Select All"

func _set_group_selection(selected: bool):
	for button in _get_group_checkbuttons():
		button.button_pressed = selected
	_update_select_all_button_text()

func _on_wordset_toggled(_is_pressed: bool, _button: CheckButton):
	_update_select_all_button_text()

func _on_done_pressed():
	var paths = []
	for path in wordset_buttons.keys():
		var child = wordset_buttons[path]
		if child is CheckButton and child.button_pressed:
			paths.append(path)
	
	if paths.size() > 0:
		pending_export_paths = paths
		# Open Folder Picker
		DisplayServer.file_dialog_show(
			"Select Export Folder",
			"",
			"",
			false,
			DisplayServer.FILE_DIALOG_MODE_OPEN_DIR,
			[],
			_on_folder_selected
		)
	else:
		# If nothing selected, just leave
		get_tree().change_scene_to_file("res://scenes/add_word_set.tscn")

# This callback runs after the user selects a folder
func _on_folder_selected(status: bool, selected_paths: PackedStringArray, _index: int):
	if status and selected_paths.size() > 0:
		var target_folder = selected_paths[0]
		
		for source_path in pending_export_paths:
			var filename = source_path.get_file()
			var dest_path = target_folder.path_join(filename)
			
			# No need for DirAccess.new()! 
			# DirAccess.copy_absolute is static and works on its own.
			if FileAccess.file_exists(source_path):
				var err = DirAccess.copy_absolute(source_path, dest_path)
				if err == OK:
					print("Exported: " + filename)
				else:
					print("Error exporting " + filename + ": " + str(err))
		
		# Clear list and move on
		pending_export_paths = []
		get_tree().change_scene_to_file("res://scenes/add_word_set.tscn")

func _on_cancel_pressed():
	get_tree().change_scene_to_file("res://scenes/add_word_set.tscn")

func _on_back_pressed():
	if list:
		list.visible = true
	if word_group:
		word_group.visible = false
	_update_select_all_button_text()

func _on_select_all_pressed():
	var buttons = _get_group_checkbuttons()
	if buttons.is_empty():
		return

	var all_selected = true
	for button in buttons:
		if not button.button_pressed:
			all_selected = false
			break

	_set_group_selection(not all_selected)
