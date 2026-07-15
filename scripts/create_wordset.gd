extends Control

@export var list: Control
@export var item: PackedScene
@export var nameedit: LineEdit

func _ready():
	list.add_child(item.instantiate())

func _on_add_word_pressed():
	list.add_child(item.instantiate())

func clean_file_name(input_string: String) -> String:
	# 1. Convert everything to lowercase first
	var lower_text = input_string.to_lower()
	
	# 2. Replace all spaces with underscores
	var text_with_underscores = lower_text.replace(" ", "_")
	
	# 3. Strip out any remaining non-safe file characters
	var regex = RegEx.new()
	regex.compile("[^a-z0-9_.-]") # Keeps letters, numbers, underscores, dots, and hyphens
	var final_name = regex.sub(text_with_underscores, "", true)
	
	# 4. Check if empty
	if final_name.is_empty():
		return "" # Or return a default name like "unnamed_file"
		
	return final_name

func _on_done_pressed():
	if clean_file_name(nameedit.text) == "":
		return
	
	# 1. Initialize the structure correctly
	var wordset = {
		"name": nameedit.text,
		"words": {}
	}
	
	# 2. Safely populate the dictionary
	for child in list.get_children():
		var word = child.get_node("HBoxContainer/WordEdit").text
		var hint = child.get_node("HintEdit").text
		if not word.is_empty(): # Avoid empty keys
			wordset["words"][word] = hint
	
	# 3. Check for minimum word count
	if wordset["words"].size() < 1:
		print("Needs 1 word!")
		return
		
	# 4. Handle Directory Creation (for user://)
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("wordsets"):
		dir.make_dir("wordsets")
		
	# 5. Save to user:// (Export-safe)
	var path = "user://wordsets/" + clean_file_name(nameedit.text) + ".json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	
	if file:
		file.store_line(JSON.stringify(wordset))
		file.close()
		print("Saved to: " + path)
		get_tree().change_scene_to_file("res://scenes/words.tscn")
	else:
		print("Failed to open file for saving: " + str(FileAccess.get_open_error()))

func _on_cancel_pressed():
	get_tree().change_scene_to_file("res://scenes/add_word_set.tscn")
