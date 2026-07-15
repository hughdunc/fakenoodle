extends Node

var players: Array = ["Player 1", "Player 2", "Player 3"]
var imposters: int = 1
var imposter_hint: bool = true

# This dictionary stores the path as the key and the enabled boolean as the value
var wordsets: Dictionary = {}

var imposter_indexes = []
var word: String = ""
var hint: String = ""

func _ready():
	# 1. Ensure default files are copied to the persistent user folder
	setup_default_wordsets()
	
	# 2. Populate the wordsets dictionary from the user folder
	load_wordsets_from_folder()

# --- SETUP & FILE LOADING ---

func setup_default_wordsets():
	var source_folder = "res://wordsets/"
	var dest_folder = "user://wordsets/"
	
	# Ensure the user folder exists
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("wordsets"):
		dir.make_dir("wordsets")
		
	# Copy default files from res:// to user:// if they aren't already there
	var source_dir = DirAccess.open(source_folder)
	if source_dir:
		source_dir.list_dir_begin()
		var file_name = source_dir.get_next()
		while file_name != "":
			if not source_dir.current_is_dir() and file_name.ends_with(".json"):
				var dest_path = dest_folder + file_name
				if not FileAccess.file_exists(dest_path):
					source_dir.copy(source_folder + file_name, dest_path)
					print("Copied default file: " + file_name)
			file_name = source_dir.get_next()
		source_dir.list_dir_end()

func load_wordsets_from_folder():
	var folder = "user://wordsets/"
	var dir = DirAccess.open(folder)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var full_path = folder + file_name
				
				# Read the JSON to find the "enabled" value
				var json_string = FileAccess.get_file_as_string(full_path)
				var data = JSON.parse_string(json_string)
				
				# Default to 'true' if the file is missing the key, or use the actual value
				var is_enabled = true
				if data and data.has("enabled"):
					is_enabled = data["enabled"]
				
				wordsets[full_path] = is_enabled
				
			file_name = dir.get_next()
		dir.list_dir_end()

# --- DATA ACCESS ---

func get_wordset_list():
	load_wordsets_from_folder()
	var list = {}
	for ws in wordsets:
		if FileAccess.file_exists(ws):
			var json_string = FileAccess.get_file_as_string(ws)
			var data = JSON.parse_string(json_string)
			if data and data.has("name"):
				list[data["name"]] = ws
	return list

func get_wordset(path):
	if FileAccess.file_exists(path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if data and data.has("words"):
			return data["words"]
	return {}

# --- GAME LOGIC ---

func decide_imposters():
	var idxs = range(len(players))
	idxs.shuffle()
	idxs.resize(imposters)
	imposter_indexes = idxs
	return idxs

func decide_word():
	# 1. Gather all ENABLED wordset paths
	var enabled_paths = []
	for ws in wordsets:
		if wordsets[ws]: # If enabled
			if FileAccess.file_exists(ws):
				enabled_paths.append(ws)
	
	# 2. Safety check: If no wordsets are enabled or found, return empty
	if enabled_paths.is_empty():
		return {}
		
	# 3. Pick one random wordset path first
	var chosen_path = enabled_paths.pick_random()
	
	# 4. Get the words from that specific set
	var words = get_wordset(chosen_path)
	
	# 5. Safety check: If the chosen file exists but has no words
	if words.is_empty():
		return {}
		
	# 6. Pick a random word from ONLY that wordset
	word = words.keys().pick_random()
	hint = words[word]
	
	return {word: hint}
