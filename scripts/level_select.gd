extends Button

var difficulty_range

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func get_diff():
	return difficulty_range

func set_diff(range):
	difficulty_range = range


func _on_pressed():
	get_node("/root/Control").begin(self.text, range(difficulty_range[1], difficulty_range[0]).pick_random())
