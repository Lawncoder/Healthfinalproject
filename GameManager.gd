extends Control

#region Scenes
@onready var moneyLabel: RichTextLabel = $Money
@onready var popularityProgressBar: ProgressBar = $VBoxContainer/Popularity
const ICON = preload("res://icon.svg")
@onready var grid_container: GridContainer = $GridContainer
@onready var rich_text_label_2: RichTextLabel = $Panel/VBoxContainer/RichTextLabel2



#endregion


var popularity = 100;
var money = 100;
var cities :Array = [];
const wealth_per_turn = 2500;
var distribution = [30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 50, 50, 50, 50, 50, 50, 50, 70, 70, 70, 70, 70, 100, 100, 100, 150, 150, 300, 500];
var selected : City = null;
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	distribution.shuffle()
	for i in 24:
		var city : City = City.new();
		city.revenue = distribution.pop_front();
		
		var node = Button.new()
		node.icon = ICON;
		node.text = "";
		var sig : Signal = node.button_down;
		sig.connect(clicked_on.bind(i));
		grid_container.add_child(node);
		cities.append([city, node]);
	#grid_container.pivot_offset = grid_container.size/2;
	cities.pick_random()[0].infected = 1;
	
	call_deferred("set_grid_pos")
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#update ui
	moneyLabel.text = "Money: %d" % money;
	popularityProgressBar.value = popularity;
	popularity -= delta;
	money += delta;
	update_inspector()
	
	
	
func set_grid_pos():
	grid_container.position = (self.size - grid_container.size*grid_container.scale.x)/2;
		

func update_inspector():
	if (selected == null):
		rich_text_label_2.text = "No City Selected";
	else:
		rich_text_label_2.text = "Alive: %d \n Infected: %d \n Dead: %d \n Revenue: %d" % [selected.population-selected.dead, selected.infected, selected.dead, selected.revenue];
func clicked_on(i):
	selected = cities[i][0];
