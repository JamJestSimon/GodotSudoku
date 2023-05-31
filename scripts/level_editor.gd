extends Control

var pencil_mode = false

var Panel_scene = preload("res://scenes/panel.tscn")
var button_scene = preload("res://scenes/button.tscn")
var button_group = preload("res://misc/button_group.tres")
var sudoku_panels
var sudoku_grid
var counter
var insert_value

# Called when the node enters the scene tree for the first time.
func _ready():
	sudoku_panels = []
	sudoku_grid = []
	for i in range(9):
		sudoku_panels.append([])
		sudoku_grid.append([])
		for j in range(9):
			var panel = Panel_scene.instantiate()
			get_node("GridContainer").get_child(j / 3 + 3 * (i / 3)).add_child(panel)
			panel.set_row(i)
			panel.set_col(j)
			panel.set_interact(false)
			panel.interact = true
			sudoku_panels[i].append(panel)
			sudoku_grid[i].append("")
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func set_value(value):
	insert_value = value

func get_value():
	return insert_value

func set_field(row, col, value):
	sudoku_grid[row][col] = value

func export():
	if check_valid(sudoku_grid):
		solve_grid(sudoku_grid)
		if counter == 1:
			
			pass
		else:
			print_debug("Unsolvable board")
			pass
	else:
		print_debug("Invalid board state")
		pass
	# Error popup to implement

func check_valid(grid):
	var row
	var col
	for i in range(81):
		row = i / 9 as int
		col = i % 9
		if grid[row][col] != "":
			if !check_presence(grid, row, col, grid[row][col]):
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

func grid_full(grid):
	for i in range(9):
		for j in range(9):
			if grid[i][j] == "":
				return false
	return true

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
