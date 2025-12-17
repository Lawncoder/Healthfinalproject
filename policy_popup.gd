extends Panel

@onready var v_box_container: VBoxContainer = $Panel/VBoxContainer

var results = []

signal policies_picked(results)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_button_up() -> void:
	visible = false
	for child in v_box_container.get_children():
		results.append(child.get_results())
		
		child.queue_free()
	policies_picked.emit(results)


func add_policies(nodes):
	for node in nodes:
		v_box_container.add_child(node)
	results = []
	visible = true
