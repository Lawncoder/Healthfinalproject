extends Control

#region Scenes
@onready var moneyLabel: RichTextLabel = $Money
@onready var popularityProgressBar: ProgressBar = $VBoxContainer/Popularity
const ICON = preload("res://icon.svg")
@onready var grid_container: GridContainer = $GridContainer
@onready var rich_text_label_2: RichTextLabel = $Panel/VBoxContainer/RichTextLabel2
#endregion


var pathogen : Pathogen;
var popularity = 100;
var money = 100;
var cities :Array = [];
const wealth_per_turn = 2500;
var distribution = [30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 50, 50, 50, 50, 50, 50, 50, 70, 70, 70, 70, 70, 100, 100, 100, 150, 150, 300, 500];
var icons = [];
var selected : City = null;

var infection_log = []
var infection_change_log = []
@export var turns_left = 20;
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pathogen = Pathogen.new()
	var vector = randi_range(0,3)
	match vector:
		0:
			pathogen.attack_vector = Pathogen.Vectors.WATER
		1:
			pathogen.attack_vector = Pathogen.Vectors.AIR
		2:
			pathogen.attack_vector = Pathogen.Vectors.TOUCH
		3: 
			pathogen.attack_vector = Pathogen.Vectors.FOOD

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
		cities.append(city);
		icons.append(node);
	#grid_container.pivot_offset = grid_container.size/2;
	var random = randi_range(0,23)
	cities[random].infected = 1;
	icons[random].modulate=Color(1,0.2,0.2,1)
	
	
	
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
		rich_text_label_2.text = "Alive: %d \n Infected: %d \n Dead: %d \n Revenue: %d\nImmune: %d\n Change: %d" % [selected.population-selected.dead, selected.infected, selected.dead, selected.revenue,selected.immune, infection_change_log[infection_change_log.size()-1][cities.find(selected)] if turns_left != 20 else selected.infected];
func clicked_on(i):
	selected = cities[i];
	


func _on_next_button_up() -> void:
	#Simulate turn logic
	simulate_infection()
	simulate_events()
	update_money_and_popularity()
	turns_left-=1
	if infection_log.size()>0:print(infection_log[infection_log.size()-1][0])
func simulate_infection():
	var counter = 0;
	var pre_simulation_infected = [];
	var changes_in_infection = []
	for city in cities:
		pre_simulation_infected.append(city.infected)
		var to_infect = (pathogen.infection_rate + randf_range(-0.1, 0.1)) * city.infected;
		
		to_infect = ceil(to_infect)
		var to_infect_other_cities = pathogen.city_spread_rate * to_infect;
		to_infect_other_cities = floor(to_infect_other_cities)
		to_infect -= to_infect_other_cities;
		if city.infected + to_infect > city.population - city.immune:
			to_infect = max(city.population - city.immune - city.infected,0);
		city.infected += to_infect;

		changes_in_infection.append(to_infect)
		#cities.pick_random().infected += to_infect_other_cities;
	infection_log.append(pre_simulation_infected)
	infection_change_log.append(changes_in_infection)
	counter = 0;
	for city in cities:
		city.infected = clampi(city.infected, 0, city.population - city.immune)
		if 20 - turns_left >= pathogen.number_of_turns_held:
			var passed = infection_change_log[infection_change_log.size()-pathogen.number_of_turns_held-1][counter]
			
			
			var dead = floor(passed * pathogen.death_rate)
			var immune = passed-dead;
			#immune = floor(immune * 0.9); #magic number, TODO: make it configurable in pathogen data
			city.population -= dead;
			city.immune += immune;
			city.infected -= passed;
			
		var color : Color = icons[counter].modulate
		icons[counter].modulate.b = (1-(city.infected*1.0/city.population))  + (city.infected * 1.0/city.population)*0.2
		icons[counter].modulate.g = (1-(city.infected*1.0/city.population))  + (city.infected* 1.0/city.population)*0.15
		counter+=1;
	

func simulate_events():
	pass
func update_money_and_popularity():
	pass
enum grid_placements {
	CORNER, EDGE, SURROUNDED
}
func get_grid_placement(i) -> grid_placements:
	if (i==0 or i == 23 or i == 5 or i==18):
		return grid_placements.CORNER
	var row = floor(i/6)
	var column = i%6
	if (column == 0 or column == 5 or row == 0 or row == 3):
		return grid_placements.EDGE
	return grid_placements.SURROUNDED
