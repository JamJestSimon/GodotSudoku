extends Button

var value

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func set_value(new_value):
	value = new_value

func _on_pressed():
	get_node("/root/Control").set_value(value)
