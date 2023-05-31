extends Control

var Panel_scene = preload("res://scenes/panel.tscn")
var button_scene = preload("res://scenes/button.tscn")
var button_group = preload("res://misc/button_group.tres")
var level_container = preload("res://scenes/level_container.tscn")
var level_editor_scene = preload("res://scenes/level_editor.tscn")
var level_editor_button = preload("res://scenes/level_editor_button.tscn")
var insert_value = ""
var levels
var selected_level
var level_labels = []
var sudoku_panels
var sudoku_grid
var solved_sudoku_grid
var counter
var time_elapsed
var victory_state
var pencil_mode

# Called when the node enters the scene tree for the first time.
func _ready():
	time_elapsed = 0.0
	victory_state = false
	sudoku_panels = []
	solved_sudoku_grid = []
	for i in range(9):
		sudoku_panels.append([])
		solved_sudoku_grid.append([])
		for j in range(9):
			var panel = Panel_scene.instantiate()
			get_node("GridContainer").get_child(j / 3 + 3 * (i / 3)).add_child(panel)
			panel.set_row(i)
			panel.set_col(j)
			sudoku_panels[i].append(panel)
			solved_sudoku_grid[i].append("")
	for i in range(9):
		var button = button_scene.instantiate() as Button
		button.text = str(i + 1)
		button.button_group = button_group
		var shortcut_key = InputEventKey.new()
		shortcut_key.pressed = true
		shortcut_key.keycode = KEY_0 + i + 1
		button.shortcut = Shortcut.new()
		button.shortcut.events.append(shortcut_key)
		button.set_value(i + 1)
		get_node("HBoxContainer").add_child(button)
	var button = button_scene.instantiate() as Button
	button.text = "Clear"
	button.button_group = button_group
	var shortcut_key = InputEventKey.new()
	shortcut_key.pressed = true
	shortcut_key.keycode = KEY_0
	button.shortcut = Shortcut.new()
	button.shortcut.events.append(shortcut_key)
	button.set_value("")
	get_node("HBoxContainer").add_child(button)
	var levels_file = FileAccess.open("res://data/levels.json", FileAccess.READ)
	var json = JSON.new()
	while levels_file.get_position() < levels_file.get_length():
		var json_string = levels_file.get_line()
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue
		var node_data = json.get_data()
		get_node("BestTimeSave").fill_best_times(node_data["levels"].size())
		load_game()
		levels = node_data["levels"]
		for i in levels:
			var level_selection = level_container.instantiate()
			get_node("LevelRect/VBoxContainer").add_child(level_selection)
			(level_selection.get_child(0) as Button).text = i
			level_selection.get_child(0).set_diff(node_data[i])
			level_labels.append(level_selection.get_child(1) as Label)
	var editor_button = level_editor_button.instantiate()
	get_node("LevelRect/VBoxContainer").add_child(editor_button)
	(editor_button as Button).pressed.connect(level_editor)
	level_select()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not victory_state:
		time_elapsed += delta
	(get_node("Time Label") as Label).text = format_time(time_elapsed)

func level_select():
	time_elapsed = 0.0
	victory_state = true
	(get_node("ShadePanel") as Panel).visible = true
	(get_node("LevelRect") as ColorRect).visible = true
	(get_node("WinRect") as ColorRect).visible = false
	for i in level_labels:
		i.text = "Best Time: " + alt_format_time(get_node("BestTimeSave").best_times[level_labels.find(i)])

func begin(level, fields):
	(get_node("ShadePanel") as Panel).visible = false
	(get_node("LevelRect") as ColorRect).visible = false
	selected_level = level
	generate_board(fields)
	victory_state = false

func generate_board(fields_left):
	var row
	var col
	fill_grid(solved_sudoku_grid)
	sudoku_grid = []
	for i in range(9):
		sudoku_grid.append([])
		for j in range(9):
			sudoku_grid[i].append(solved_sudoku_grid[i][j])
	var fields = range(81)
	var fields_pick = []
	for i in fields:
		fields_pick.append(i)
	while fields.size() > fields_left && fields_pick.size() > 0:
		randomize()
		var chosen = fields_pick.pick_random()
		row = chosen / 9 as int
		col = chosen % 9 as int
		var backup = sudoku_grid[row][col]
		sudoku_grid[row][col] = ""
		var copy_grid = []
		for i in range(9):
			copy_grid.append([])
			for j in range(9):
				copy_grid[i].append(sudoku_grid[i][j])
		counter = 0
		solve_grid(copy_grid)
		if counter != 1:
			sudoku_grid[row][col] = backup
			fields_pick.remove_at(fields_pick.find(chosen))
		else:
			fields.remove_at(fields.find(chosen))
			fields_pick.clear()
			for i in fields:
				fields_pick.append(i)
	draw_grid()
	victory_state = false

func draw_grid():
	for i in range(9):
		for j in range(9):
			if sudoku_grid[i][j] != "":
				sudoku_panels[i][j].set_interact(false)
				sudoku_panels[i][j].set_value(sudoku_grid[i][j])
			else:
				sudoku_panels[i][j].set_interact(true)
				sudoku_panels[i][j].set_value("")

func grid_full(grid):
	for i in range(9):
		for j in range(9):
			if grid[i][j] == "":
				return false
	return true

func solve_grid(grid):
	var row
	var col
	for i in range(81):
		row = i / 9 as int
		col = i % 9
		if grid[row][col] == "":
			for value in range(1, 10):
				if check_presence(grid, row, col, value):
					grid[row][col] = str(value)
					if grid_full(grid):
						counter += 1
						break
					else:
						if solve_grid(grid):
							return true
			break
	grid[row][col] = ""

var number_list = [1, 2, 3, 4, 5, 6, 7, 8, 9]

func fill_grid(grid):
	var row
	var col
	for i in range(81):
		row = i / 9 as int
		col = i % 9
		if grid[row][col] == "":
			randomize()
			number_list.shuffle()
			for value in number_list:
				if check_presence(grid, row, col, value):
					grid[row][col] = str(value)
					if grid_full(grid):
						return true
					else:
						if fill_grid(grid):
							return true
			break
	grid[row][col] = ""

func check_presence(grid, row, col, value):
	if not str(value) in grid[row]:
		if not str(value) in [grid[0][col], grid[1][col], grid[2][col], grid[3][col], grid[4][col], grid[5][col], grid[6][col], grid[7][col], grid[8][col]]:
			var square = []
			for i in range(0,3):
				for j in range(0,3):
					square.append(grid[i + 3 * (row / 3)][j + 3 * (col / 3)])
			if not str(value) in square:
				return true
	return false

func set_field(row, col, value):
	sudoku_grid[row][col] = value
	for i in range(9):
		sudoku_panels[row][i].erase_pencil_marking(int(value) - 1)
	for i in range(9):
		sudoku_panels[i][col].erase_pencil_marking(int(value) - 1)
	for i in range(0,3):
		for j in range(0,3):
			sudoku_panels[i + 3 * (row / 3)][j + 3 * (col / 3)].erase_pencil_marking(int(value) - 1)
	if sudoku_grid == solved_sudoku_grid:
		victory_state = true
		(get_node("WinRect") as ColorRect).visible = true
		(get_node("ShadePanel") as Panel).visible = true
		(get_node("WinRect/Time Label") as Label).text = (get_node("Time Label") as Label).text
		var level = levels.find(selected_level)
		if get_node("BestTimeSave").best_times[level] == -1 or get_node("BestTimeSave").best_times[level] > time_elapsed:
			get_node("BestTimeSave").best_times[level] = time_elapsed as int
		save_game()
		(get_node("WinRect/BestTimeLabel") as Label).text = format_time(get_node("BestTimeSave").best_times[level])

func format_time(time):
	if time == -1:
		return "--"
	var hours = (time as int) / 3600
	var minutes = (time as int) / 60
	var seconds = (time as int) % 60
	var time_string = ""
	var time_array = []
	if hours > 0:
		time_string += "%02d h "
		time_array.append(hours)
	if minutes > 0:
		time_string += "%02d m "
		time_array.append(minutes)
	time_string += "%02d s"
	time_array.append(seconds)
	return time_string % time_array

func alt_format_time(time):
	if time == -1:
		return "--:--"
	var minutes = (time as int) / 60
	var seconds = (time as int) % 60
	return "%02d:%02d" % [minutes, seconds]

func set_value(value):
	insert_value = value

func get_value():
	return insert_value

func clear_grid(grid):
	for i in range(9):
		for j in range(9):
			grid[i][j] = ""

func _on_restart_button_pressed():
	(get_node("WinRect") as ColorRect).visible = false
	clear_grid(solved_sudoku_grid)
	clear_grid(sudoku_grid)
	draw_grid()
	level_select()

func _on_show_sudoku_button_pressed():
	(get_node("WinRect") as ColorRect).visible = false
	(get_node("ShadePanel") as Panel).visible = false

func _on_pencil_mode_button_toggled(button_pressed):
	pencil_mode = button_pressed

func level_editor():
	var root = get_tree().get_root()

	var level = get_tree().get_current_scene()
	root.remove_child(level)
	level.call_deferred("free")

	var level_editor = level_editor_scene.instantiate()
	root.add_child(level_editor)

func save_game():
	var save_game = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	for node in save_nodes:
		if node.scene_file_path.is_empty():
			print("persistent node '%s' is not an instanced scene, skipped" % node.name)
			continue

		if !node.has_method("save"):
			print("persistent node '%s' is missing a save() function, skipped" % node.name)
			continue

		var node_data = node.call("save")

		var json_string = JSON.stringify(node_data)

		save_game.store_line(json_string)

func load_game():
	if not FileAccess.file_exists("user://savegame.save"):
		return
	
	var save_game = FileAccess.open("user://savegame.save", FileAccess.READ)
	while save_game.get_position() < save_game.get_length():
		var json_string = save_game.get_line()
		
		var json = JSON.new()
		
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue
		
		var node_data = json.get_data()
		
		for i in range(node_data["best-times"].size()):
			get_node("BestTimeSave").best_times[i] = node_data["best-times"][i]
