extends Panel

@onready var check_box: CheckBox = $HBoxContainer/CheckBox
var policy : Policy
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func get_results():
	return {policy.identifier:check_box.button_pressed}
