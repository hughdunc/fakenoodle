extends Control

@export var item: PackedScene
@export var list: Control

# We need this to remember which files to export while the file picker is open
var pending_export_paths: Array = []

func _ready():
	var wsl = Global.get_wordset_list()
	for ws in wsl:
		var i = item.instantiate()
		i.text = ws
		i.path = wsl[ws]
		i.button_pressed = false
		list.add_child(i)

func _on_done_pressed():
	var paths = []
	for child in list.get_children():
		if child.button_pressed: 
			paths.append(child.path)
	
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
