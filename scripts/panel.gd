extends Panel

var label
var sub_label = preload("res://scenes/label.tscn")
var label_list = []
var interact
var pencil_mode
var row
var col

# Called when the node enters the scene tree for the first time.
func _ready():
	label = get_child(0) as Label
	for i in range(9):
		var label_instance = sub_label.instantiate()
		label_list.append(label_instance as Label)
		get_node("GridContainer").add_child(label_instance)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func set_interact(interact_mode):
	interact = interact_mode
	if interact as bool:
		label.add_theme_color_override("font_color", Color("TEAL"))
	else:
		label.add_theme_color_override("font_color", Color("BLACK"))

func set_value(value):
	label.text = value

func set_row(value):
	row = value
	
func set_col(value):
	col = value

func erase_pencil_marking(value):
	if value > -1:
		label_list[value].text = ""

func _on_gui_input(event):
	if interact:
		var input = get_node("/root/Control").get_value()
		if event is InputEventMouseButton:
			if (event as InputEventMouseButton).button_index == 1 and (event as InputEventMouseButton).pressed:
				if get_node("/root/Control").pencil_mode:
					if str(input) != "":
						if label_list[input - 1].text != "":
							label_list[input - 1].text = ""
						else:
							label_list[input - 1].text = str(input)
						label.text = ""
				else:
					for i in range(9):
						label_list[i].text = ""
					label.text = str(input)
					get_node("/root/Control").set_field(row, col, label.text)
		elif event is InputEventScreenTouch:
			if get_node("/root/Control").pencil_mode:
				if str(input) != "":
					if label_list[input - 1].text != "":
						label_list[input - 1].text = ""
					else:
						label_list[input - 1].text = str(input)
					label.text = ""
			else:
				for i in range(9):
					label_list[i].text = ""
				label.text = str(input)
				get_node("/root/Control").set_field(row, col, label.text)
