extends Node

const SETTINGS_PATH := "user://config/settings.json"
const DEFAULT_SETTINGS := {
	"imposter_hint": true,
	"imposter_starting_chance": 50.0,
	"imposter_goes_again_chance": 50.0
}

var players: Array = ["Player 1", "Player 2", "Player 3"]
var imposters: int = 1
var imposter_hint: bool = true
var imposter_starting_chance: float = 50.0
var imposter_goes_again_chance: float = 50.0
var settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)

# This dictionary stores the path as the key and the enabled boolean as the value
var wordsets: Dictionary = {}

var imposter_indexes = []
var word: String = ""
var hint: String = ""

# NEW: Keeps track of how many consecutive times a player has been the imposter
var imposter_streaks: Dictionary = {}

func _ready():
	# 1. Ensure default files are copied to the persistent user folder
	setup_default_wordsets()
	# 2. Ensure the persistent settings file exists and load it
	ensure_settings_file()
	load_settings()
	
	# 3. Populate the wordsets dictionary from the user folder
	load_wordsets_from_folder()

func ensure_settings_file():
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("config"):
		dir.make_dir_recursive("config")

	if not FileAccess.file_exists(SETTINGS_PATH):
		save_settings(DEFAULT_SETTINGS)

func load_settings():
	var loaded_settings = DEFAULT_SETTINGS.duplicate(true)
	if FileAccess.file_exists(SETTINGS_PATH):
		var parsed_settings = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
		if parsed_settings is Dictionary:
			for key in DEFAULT_SETTINGS.keys():
				if parsed_settings.has(key):
					loaded_settings[key] = parsed_settings[key]

	settings = loaded_settings
	imposter_hint = bool(settings.get("imposter_hint", DEFAULT_SETTINGS["imposter_hint"]))
	imposter_starting_chance = float(settings.get("imposter_starting_chance", DEFAULT_SETTINGS["imposter_starting_chance"]))
	
	# Fixed a small typo here (removed the square brackets around DEFAULT_SETTINGS)
	imposter_goes_again_chance = float(settings.get("imposter_goes_again_chance", DEFAULT_SETTINGS["imposter_goes_again_chance"]))
	
	settings["imposter_hint"] = imposter_hint
	settings["imposter_starting_chance"] = imposter_starting_chance
	settings["imposter_goes_again_chance"] = imposter_goes_again_chance
	save_settings(settings)

func save_settings(value: Dictionary = settings):
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("config"):
		dir.make_dir_recursive("config")

	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(value))
		file.close()

func get_setting(key: String, default_value = null):
	if key == "players":
		return players
	if key == "imposters":
		return imposters
	if settings.has(key):
		return settings[key]
	return default_value

func set_setting(key: String, value):
	match key:
		"players":
			players = value
			return
		"imposters":
			imposters = int(value)
			return
		"imposter_hint":
			imposter_hint = bool(value)
			settings[key] = imposter_hint
		"imposter_starting_chance":
			imposter_starting_chance = float(value)
			settings[key] = imposter_starting_chance
		"imposter_goes_again_chance":
			imposter_goes_again_chance = float(value)
			settings[key] = imposter_goes_again_chance
		_:
			settings[key] = value
	save_settings(settings)

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
	var player_count = len(players)
	if player_count == 0:
		imposter_indexes = []
		return imposter_indexes

	# Ensure all players exist in the streak dictionary (defaults to 0)
	for p in players:
		if not imposter_streaks.has(p):
			imposter_streaks[p] = 0

	var remaining_indexes = range(player_count)
	var selected_indexes: Array = []
	var target_count = mini(imposters, player_count)
	var chance_multiplier = clampf(imposter_goes_again_chance / 100.0, 0.0, 1.0)

	# Pick imposters one by one to ensure the math remains perfect
	while selected_indexes.size() < target_count and not remaining_indexes.is_empty():
		var current_pool_size = remaining_indexes.size()
		
		var normal_count = 0
		for idx in remaining_indexes:
			if imposter_streaks[players[idx]] == 0:
				normal_count += 1
				
		var total_streak_prob = 0.0
		var temp_probs = {}
		var pool_base_chance = 1.0 / float(current_pool_size)
		
		# 1. Calculate the modified chance for players who have a streak
		for idx in remaining_indexes:
			var streak = imposter_streaks[players[idx]]
			if streak > 0:
				# Math: base_chance * (multiplier ^ streak)
				# Example: 0.25 * (0.5 ^ 1) = 0.125
				var prob = pool_base_chance * pow(chance_multiplier, streak)
				temp_probs[idx] = prob
				total_streak_prob += prob
				
		# 2. Distribute the remaining probability evenly to normal players
		var normal_prob = 0.0
		if normal_count > 0:
			var remaining_prob = maxf(0.0, 1.0 - total_streak_prob)
			normal_prob = remaining_prob / float(normal_count)
			
		# 3. Create the weight list mapped to the remaining players
		var weights = []
		var total_weight = 0.0
		for idx in remaining_indexes:
			var w = temp_probs[idx] if imposter_streaks[players[idx]] > 0 else normal_prob
			weights.append(w)
			total_weight += w
			
		# 4. Roll the dice
		var roll = randf() * total_weight
		var current_weight = 0.0
		var pick_pool_index = 0
		
		for i in range(len(weights)):
			current_weight += weights[i]
			if roll <= current_weight:
				pick_pool_index = i
				break
				
		# 5. Add them to the selected list and remove from the pool
		selected_indexes.append(remaining_indexes[pick_pool_index])
		remaining_indexes.remove_at(pick_pool_index)

	selected_indexes.sort()
	imposter_indexes = selected_indexes
	
	# 6. Update streaks for the NEXT game
	for i in range(player_count):
		var p_name = players[i]
		if i in imposter_indexes:
			imposter_streaks[p_name] += 1
		else:
			imposter_streaks[p_name] = 0 # Reset to 0 if they weren't imposter
			
	return selected_indexes

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
