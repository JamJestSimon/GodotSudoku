extends Control

var Panel_scene = preload("res://scenes/panel.tscn")
var button_scene = preload("res://scenes/button.tscn")
var button_group = preload("res://misc/button_group.tres")
var insert_value = ""
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
		button.set_value(i + 1)
		get_node("HBoxContainer").add_child(button)
	var button = button_scene.instantiate() as Button
	button.text = "Clear"
	button.button_group = button_group
	button.set_value("")
	get_node("HBoxContainer").add_child(button)
	generate_board()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not victory_state:
		time_elapsed += delta
	var hours = (time_elapsed as int) / 3600
	var minutes = (time_elapsed as int) / 60
	var seconds = (time_elapsed as int) % 60
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
	(get_node("Time Label") as Label).text = time_string % time_array

func generate_board():
	var row
	var col
	fill_grid(solved_sudoku_grid)
	sudoku_grid = []
	for i in range(9):
		sudoku_grid.append([])
		for j in range(9):
			sudoku_grid[i].append(solved_sudoku_grid[i][j])
	var attempts = 5
	counter = 1
	while attempts > 0:
		randomize()
		row = randi_range(0, 8)
		randomize()
		col = randi_range(0, 8)
		while sudoku_grid[row][col] == "":
			randomize()
			row = randi_range(0, 8)
			randomize()
			col = randi_range(0, 8)
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
			attempts -= 1
	draw_grid()

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
		(get_node("WinPanel") as Panel).visible = true
		(get_node("WinRect/Time Label") as Label).text = (get_node("Time Label") as Label).text

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
	(get_node("WinPanel") as Panel).visible = false
	victory_state = false
	time_elapsed = 0.0
	clear_grid(solved_sudoku_grid)
	clear_grid(sudoku_grid)
	draw_grid()
	generate_board()


func _on_show_sudoku_button_pressed():
	(get_node("WinRect") as ColorRect).visible = false
	(get_node("WinPanel") as Panel).visible = false


func _on_pencil_mode_button_toggled(button_pressed):
	pencil_mode = button_pressed
