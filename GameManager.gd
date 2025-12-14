extends Control

#region Scenes
@onready var moneyLabel: RichTextLabel = $Money
@onready var popularityProgressBar: ProgressBar = $VBoxContainer/Popularity
const ICON = preload("res://icon.svg")
@onready var grid_container: GridContainer = $GridContainer
@onready var rich_text_label_2: RichTextLabel = $Panel/VBoxContainer/RichTextLabel2
@onready var next_turn_cooldown_timer: Timer = $NextTurnCooldownTimer
@onready var next_turn_progress_bar: ProgressBar = $NextTurnButtonPanle/VBoxContainer/NextTurnProgressBar
const INFECTION_SPREAD = preload("res://infection_spread.tscn")
@onready var turns_left_label: RichTextLabel = $Panel2/TurnsLeftLabel

#endregion


var pathogen : Pathogen;
var popularity = 100;
var money = 100;
var cities :Array = [];
const wealth_per_turn = 2500;
var distribution = [30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 50, 50, 50, 50, 50, 50, 50, 70, 70, 70, 70, 70, 100, 100];
var icons = [];
var selected : City = null;
var can_click_flag = true;
var immune_change_log = []
var infection_log = []
var infection_change_log = []
var totals : City = City.new();
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
	var animated_line = INFECTION_SPREAD.instantiate()
	animated_line.pointA = Vector2.ZERO
	animated_line.pointB = Vector2.ONE*100
	add_child(animated_line)
	
	k_offset = grid_container.size.x/grid_container.columns/2;
	for city : City in cities:
		totals.dead += (100-city.population)
		print(totals.dead)
		totals.population += city.population
		totals.infected += city.infected
		totals.immune+=city.immune
		totals.revenue += calculate_city_revenue(city)
	
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#update ui
	moneyLabel.text = "Money: %d" % money;
	popularityProgressBar.value = popularity;
	popularity -= delta;
	money += delta;
	next_turn_progress_bar.value = 100*(1-next_turn_cooldown_timer.time_left)
	update_inspector()
	
	
	
func set_grid_pos():
	grid_container.position = (self.size - grid_container.size*grid_container.scale.x)/2;
		

func update_inspector():
	if (selected == null):
		rich_text_label_2.text = "No City Selected";
	else:
		rich_text_label_2.text = "Alive: %d \n Infected: %d \n Dead: %d \n Revenue: %d\nResist: %d" % [selected.population, selected.infected,selected.dead, totals.revenue if selected == totals else calculate_city_revenue(selected),selected.immune];
func clicked_on(i):
	selected = cities[i];
	


func _on_next_button_up() -> void:
	#Simulate turn logic
	
	if not can_click_flag:
		return
	animation_queue.clear()
	next_turn_cooldown_timer.start()
	can_click_flag=false;
	simulate_infection()
	simulate_events()
	update_money_and_popularity()
	animate_things()
	turns_left-=1
	totals.dead = 0
	totals.population = 0
	totals.infected = 0
	totals.immune=0
	totals.revenue = 0
	for city : City in cities:
		totals.dead += (100-city.population)
		totals.population += city.population
		totals.infected += city.infected
		totals.immune+=city.immune
		totals.revenue += calculate_city_revenue(city)
		
		
		
		
var animation_queue = []
func simulate_infection():
	
		
	var counter = 0;
	var pre_simulation_infected = [];
	var changes_in_infection = []
	for i in 24:
		changes_in_infection.append(0)
	for city in cities:
		pre_simulation_infected.append(city.infected)
		var to_infect = (pathogen.infection_rate + randf_range(-0.1, 0.1)) * city.infected;
		
		to_infect = ceil(to_infect)
		var to_infect_other_cities = pathogen.city_spread_rate * to_infect;
		to_infect_other_cities = floor(to_infect_other_cities)
		to_infect -= to_infect_other_cities;
		
		#city.infected += to_infect;
		var other_city = calculate_other_city(counter)
		changes_in_infection[counter] += to_infect
		changes_in_infection[other_city] += to_infect_other_cities
		if to_infect_other_cities>0 and cities[other_city].infected==0:
			animation_queue.append([counter, other_city])
		#changes_in_infection.append(to_infect)
		#cities.pick_random().infected += to_infect_other_cities;
		counter += 1
	infection_log.append(pre_simulation_infected)
	
	counter = 0;
	var immune_changes_this_turn = []
	for city in cities:
		
		changes_in_infection[counter] = clamp(changes_in_infection[counter],0, city.population - city.immune - city.infected);
		city.infected += changes_in_infection[counter]
		#city.infected = clampi(city.infected, 0, city.population - city.immune)
		if 20 - turns_left >= pathogen.number_of_turns_held-1:
		
			var passed = infection_change_log[infection_change_log.size()-pathogen.number_of_turns_held+1][counter]
			
			
			
			var dead = ceil(passed * pathogen.death_rate)
			var immune = passed-dead;
			#immune = floor(immune * 0.9); #magic number, TODO: make it configurable in pathogen data
			city.population -= dead;
			city.immune += immune;
			immune_changes_this_turn.append(immune)
			city.infected -= passed;
			city.dead = 100-city.population
		#city.infected = max(city.infected, 0)
		counter+=1;
	infection_change_log.append(changes_in_infection)
	immune_change_log.append(immune_changes_this_turn)
	
	if 20-turns_left>=pathogen.number_of_turns_held+1:
		counter = 0
		for city in cities:
			city.immune -= immune_change_log[-pathogen.number_of_turns_held][counter]
			counter +=1;
			assert(city.infected + city.immune <= city.population)
	
 
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


func _on_next_turn_cooldown_timer_timeout() -> void:
	can_click_flag = true
	var counter = 0
	turns_left_label.text = "[center]Turns Left: %d" % [turns_left];
	for city in cities:
		icons[counter].modulate.b = (1-(city.infected*1.0/city.population))  + (city.infected * 1.0/city.population)*0.1
		icons[counter].modulate.g = (1-(city.infected*1.0/city.population))  + (city.infected* 1.0/city.population)*0.15
		icons[counter].modulate *= (1-(100-city.population)/100)
		icons[counter].modulate.a = 1
		counter += 1
		
var k_offset
func animate_things():
	k_offset = Vector2.ONE * grid_container.size.x/grid_container.columns/2
	
	
	
	for pair in animation_queue:
		var animation = INFECTION_SPREAD.instantiate()
		animation.pointA = icons[pair[0]].position+k_offset
		animation.pointB = icons[pair[1]].position+k_offset
		animation.anim_time = next_turn_cooldown_timer.wait_time
		grid_container.add_child(animation)
func calculate_other_city(i:int)->int:
	var row = i/6
	var column = i%6
	match row:
		0:
			match column:
				0:
					return [6,1].pick_random()
				5:
					return [4,11].pick_random()
				_:
					return [rc2i(row+1, column),rc2i(row, column-1),rc2i(row, column+1)].pick_random()
		3:
			match column:
				0:
					return [19,12].pick_random()
				5:
					return [22,17].pick_random()
				_:
					return [rc2i(row-1, column),rc2i(row, column-1),rc2i(row, column+1)].pick_random()
		_:
			match column:
				0:
					return [rc2i(row+1,0), rc2i(row-1,0), rc2i(row, 1)].pick_random()
				5:
					return [rc2i(row+1,5), rc2i(row-1,5), rc2i(row, 4)].pick_random()
				_:
					return [rc2i(row+1, column),rc2i(row-1, column),rc2i(row, column-1),rc2i(row, column+1)].pick_random()
	
func rc2i(row, column) -> int:
	return row*6+column;


func _on_totals_button_up() -> void:
	selected = totals
func calculate_city_revenue(city:City):
	return city.revenue*(city.population-city.infected)/100 + (city.infected/200)*city.revenue
