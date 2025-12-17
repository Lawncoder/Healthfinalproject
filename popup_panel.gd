extends Panel
@onready var rich_text_label: RichTextLabel = $VBoxContainer/RichTextLabel
@onready var rich_text_label_2: RichTextLabel = $VBoxContainer/RichTextLabel2

var heading_text = ""
var paragraph_text = ""
signal closed
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rich_text_label.text = heading_text
	rich_text_label_2.text = paragraph_text
	

func set_text(heading,paragraph):
	heading_text=heading
	paragraph_text=paragraph


func _on_button_button_up() -> void:
	visible=false
	closed.emit()
