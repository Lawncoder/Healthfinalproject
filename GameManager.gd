extends Control

#region Scenes
@onready var moneyLabel: Label = $Money
const ICON = preload("res://icon.svg")
@onready var grid_container: GridContainer = $GridContainer


@onready var rich_text_label_2:Label = $Panel/VBoxContainer/RichTextLabel2
@onready var next_turn_cooldown_timer: Timer = $NextTurnCooldownTimer
@onready var next_turn_progress_bar: ProgressBar = $NextTurnButtonPanle/VBoxContainer/NextTurnProgressBar
const INFECTION_SPREAD = preload("res://infection_spread.tscn")
@onready var turns_left_label: RichTextLabel = $Panel2/TurnsLeftLabel
@onready var totals_button: Button = $Totals
@onready var popup_panel: Panel = $PopupPanel
@onready var policy_popup: Panel = $PolicyPopup
const POLICY = preload("res://Policy.tscn")
@onready var camera_2d: Camera2D = $"../Camera2D"
@onready var hospital: Button = $OptionsPanel/VBoxContainer/Action/Hospital
@onready var ambulance: Button = $OptionsPanel/VBoxContainer/Action2/Ambulance
@onready var clinic: Button = $OptionsPanel/VBoxContainer/Action3/Clinic
@onready var ads: Button = $OptionsPanel/VBoxContainer/Action4/Ads
const GRAYSCALE = preload("res://Grayscale.gdshader")
const CHEAP = preload("res://iconset/cheap.png")
const DEV = preload("res://iconset/dev.png")
const INPROG = preload("res://iconset/inprog.png")
const BASE = preload("res://iconset/Layer 1.png")
const PARTIAL = preload("res://iconset/partial.png")
#endregion

enum INFECTION_STAGES {
	LIGHT, MODERATE, HEAVY
	#light will be few injected few dead
	#moderate is more infected some dead
	#heavy is lots infected some dead
}
enum RESOURCE_STAGES {
	UNKNOWN, UNDERSTOOD
	#understood is they have a deep understanding of the pathogen and some sort of preventative or curative treatment. Such as a vaccine or antibiotics
}
#region Research Pregramming
#turn one policies




#endregion 
#region PolicyLists
var light_unknown = []
var light_understood = []
var moderate_unknown = []
var moderate_understood = []
var heavy_unknown = []
var heavy_understood = []
#endregion
var research_budget = 0
var comms_budget = 0
var police_budget = 0

#region Simulation Variables
var cities :Array = [];
var immune_change_log = []
var infection_log = []
var infection_change_log = []
var totals : City = City.new();
var icons = [];
var selected : City = null;
var can_click_flag = true;
var pathogen : Pathogen;
#endregion

#region Money, Popularity, and Science
var money = 0;
var distribution = [30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 50, 50, 100, 100, 250, 250, 250, 400, 400, 500, 500, 1000, 1000, 2500];
var hospital_queue :Dictionary
var displayed_money = money

var science_progress = 0 #based on how high this is, the player will be given information about the pathogen

#endregion
const MY_FIRST_POLICY = preload("res://Policies/MyFirstPolicy.tres")
signal on_simulation_start
signal on_turn_end(turns_left)
signal on_turn_start
signal on_simulation_end


#region Building stats
var hospital_cost = 20000
var ambulance_cost = 12000
var clinic_cost = 7000
var ads_cost = 4000
const HOSPITAL_DEATH_RATE_IMPACT = 0.3
const CLINIC_DEATH_RATE_IMPACT = 0.7
const ADS_INFECTION_RATE_IMPACT = -1
const AMBULANCE_DEATH_RATE_IMPACT = 0.7
var ambulance_indexes = []
var information_ads : Dictionary 
#What a hospital does is that it significantly reduces the death rate for a pathogen in a city
#what an ambulance does is that it allows a hospital to reduce the death rate for nearby cities but lowers its effectiveness by half in all of them
#What a clinic does is it fulfills the same role as a hospital through reducing the death_rate but not as much (less than 1/3 as effective) but it can stack with hospitals
#ads reduce infection rates in a city but wears off
#endregion

var testing=false
enum DIRECTIVES {
		COMMS, ENFORCE, RESEARCH, NONE
}
var tutorial_counter=0
func show_tutorial():

	match tutorial_counter:
		0:
			show_information("[center]Welcome", "	You are responsible for the health of these cities in a trying time. A new pathogen has popped up and is a high profile threat")
		1:
			show_information("[center]<- Buildings", "	You must build hospitals, mobile clinics, and ambulances to control the infection. Ambulances extend a hospital's range to adjacent cities") 
		3:
			show_information("[center]<- Info-Ads", "You can launch public health awareness campaings on specific cities. These encourage good habits that prevent infection. You must wait for your team to develop the advertising material first")
		4:
			show_information("[center]Money", "Each city gives a specified amount of money per turn. Money not used will be saved. Lots of infected people and people dying will reduce the amount of money gained from a city")
		5:
			show_information("[center]The Inspector ->", "By clicking on a city, you can preview its attributes such as its revenue, infected population, developments, and more here. By selecting totals, you can see the totals for the whole population")
		6:
			show_information("[center]Good Luck","")
		2:
			show_information("[center]Buildings", "To build a development, first click on a city, and then the icon of the development you want to build")
	tutorial_counter += 1
			
@export var turns_left = 20;
func _ready() -> void:
	get_tree().create_timer(0.5).timeout.connect(show_tutorial)
	pathogen = Pathogen.new()


	distribution.shuffle()
	for i in 24:
		var city : City = City.new();
		var rev =  distribution.pop_front()
		city.revenue =rev
		
		var node = Button.new()
		
		node.icon = BASE;
		node.text = "";
		node.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		var sig : Signal = node.button_down;
		sig.connect(clicked_on.bind(i));
		grid_container.add_child(node)
		cities.append(city);
		icons.append(node);
	#grid_container.pivot_offset = grid_container.size/2;
	var random = randi_range(0,23)
	cities[random].infected = 1;

	
	
	

	
	
	k_offset = grid_container.size.x/grid_container.columns/2;
	for city : City in cities:
		totals.dead += (100-city.population)

		totals.population += city.population
		totals.infected += city.infected
		totals.immune+=city.immune
		totals.revenue += calculate_city_revenue(city)
	var counter = 0
	for city in cities:
		icons[counter].modulate.b = (1-(city.infected*1.0/city.population))  + (city.infected * 1.0/city.population)*0.1
		icons[counter].modulate.g = (1-(city.infected*1.0/city.population))  + (city.infected* 1.0/city.population)*0.15
		icons[counter].modulate *= (1-(100-city.population)/100)
		icons[counter].modulate.a = 1
		counter += 1

	money = 7450
	displayed_money = money	
	call_deferred("set_grid_pos")
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#update ui
	
	
	moneyLabel.text = "Money: %d" % displayed_money;;
	#popularityProgressBar.value = popularity;
	next_turn_progress_bar.value = 100*(1-next_turn_cooldown_timer.time_left)
	update_inspector()
	if cannot_select("hospital"):
		hospital.material.shader = GRAYSCALE
		hospital.disabled = true
	else:
		hospital.material.shader = null
		hospital.disabled = false
	if cannot_select("ads"):
		ads.material.shader = GRAYSCALE
		ads.disabled = true
	else:
		ads.material.shader = null
		ads.disabled = false
	if cannot_select("ambulance"):
		ambulance.material.shader = GRAYSCALE
		ambulance.disabled = true
	else:
		ambulance.material.shader = null
		ambulance.disabled = false
	if cannot_select("clinic"):
		clinic.material.shader = GRAYSCALE
		clinic.disabled = true
	else:
		clinic.material.shader = null
		clinic.disabled = false
	
	

func set_grid_pos():
	grid_container.position = (self.size - grid_container.size*grid_container.scale.x)/2;
	totals_button.position.y = grid_container.position.y - 50

func update_inspector():
	if (selected == null):
		rich_text_label_2.text = "No City \nSelected";
	else:
		rich_text_label_2.text = "Alive: %d \nInfected: %s \nDead: %d \nRevenue: %d\nResist: %d\nDevelopments: \n" % [selected.population, selected.infected,selected.dead, totals.revenue if selected == totals else calculate_city_revenue(selected),selected.immune] + calculate_developments_string_from_selected();

func clicked_on(i):
	selected = cities[i];

func _on_next_button_up() -> void:
	#Simulate turn logic
	end_turn()
	
var animation_queue = []
func simulate_infection():
	
	on_simulation_start.emit()
	var counter = 0;
	var pre_simulation_infected = [];
	var changes_in_infection = []
	for i in 24:
		changes_in_infection.append(0)
	for city in cities:
		pre_simulation_infected.append(city.infected)
		var infection_rate_modifier =  ADS_INFECTION_RATE_IMPACT if city.developments.has(City.DEVELOPMENTS.INFORMATION) else 1
		var to_infect = (pathogen.infection_rate*infection_rate_modifier + randf_range(-0.1, 0.1)) * city.infected;
		#print(infection_rate_modifier)
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
	for city:City in cities:
		
		changes_in_infection[counter] = clamp(changes_in_infection[counter],0, city.population - city.immune - city.infected);
		city.infected += changes_in_infection[counter]
		#city.infected = clampi(city.infected, 0, city.population - city.immune)
		if 20 - turns_left >= pathogen.number_of_turns_held-1:
		
			var passed = infection_change_log[infection_change_log.size()-pathogen.number_of_turns_held+1][counter]
			
			
			var death_rate_mods = 1.0
			if (city.developments.has(City.DEVELOPMENTS.AMBULANCE)):
				death_rate_mods *= AMBULANCE_DEATH_RATE_IMPACT
			elif city.developments.has(City.DEVELOPMENTS.HOSPITAL):
				death_rate_mods*=HOSPITAL_DEATH_RATE_IMPACT
			if city.developments.has(City.DEVELOPMENTS.CLINIC):
				death_rate_mods*=CLINIC_DEATH_RATE_IMPACT
			if city_neighbors_ambulance(cities.find(city)):
				death_rate_mods *= AMBULANCE_DEATH_RATE_IMPACT
			#print(death_rate_mods)
			var dead = ceil(passed * pathogen.death_rate * death_rate_mods)
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
	on_simulation_end.emit()
func simulate_events():
	pass
func update_money_and_popularity():
	money += totals.revenue
	
func _on_next_turn_cooldown_timer_timeout() -> void:
	if game_over:
		show_information("The Game Is Over", "[center]Your Stats:\n Alive: %d \n Dead: %d" % [totals.population, totals.dead])
	can_click_flag = true
	var counter = 0
	turns_left_label.text = "[center]Turns Left: %d" % [turns_left];
	for city in cities:
		assert(city.infected<=city.population)
		icons[counter].modulate.r=1
		icons[counter].modulate.b = (1-(city.infected*1.0/city.population))  + (city.infected * 1.0/city.population)*0.15
		icons[counter].modulate.g = (1-(city.infected*1.0/city.population))  + (city.infected* 1.0/city.population)*0.15
		icons[counter].modulate *= (1-(100-city.population)/100)
		icons[counter].modulate.a = 1

		counter += 1
	
var k_offset
func animate_things():
	k_offset = Vector2.ONE * grid_container.size.x/grid_container.columns/2
	var metric_tween = create_tween().parallel()
	metric_tween.tween_property(self, "displayed_money", money, next_turn_cooldown_timer.wait_time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	for pair in animation_queue:
		var animation = INFECTION_SPREAD.instantiate()
		#animation.scale.x = 1.0/grid_container.scale.x
		#animation.scale.y = 1.0/grid_container.scale.y
		print(animation.scale)
		animation.pointA = icons[pair[0]].global_position + icons[pair[0]].size/2 * grid_container.scale.x
		animation.pointB = icons[pair[1]].global_position + icons[pair[1]].size/2 * grid_container.scale.x
		animation.anim_time = next_turn_cooldown_timer.wait_time
		get_tree().root.add_child(animation)
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

func show_information(heading: String, information: String):
	popup_panel.heading_text = heading
	popup_panel.paragraph_text = information
	popup_panel.visible=true

func _on_policy_popup_policies_picked(results: Variant) -> void:
	end_turn()
func end_turn():
	if not can_click_flag:
		return
	on_turn_start.emit()
	animation_queue.clear()
	next_turn_cooldown_timer.start()
	can_click_flag=false;
	simulate_infection()
	simulate_events()
	update_money_and_popularity()
	animate_things()
	for city:City in information_ads.keys():
		var time_left = -information_ads.get(city)+3+turns_left
		if (time_left) <= 0:
			information_ads.erase(city)
			city.developments.remove_at(city.developments.find(City.DEVELOPMENTS.INFORMATION))
	turns_left-=1
	var keys_to_remove = []
	for key :City in hospital_queue.keys().duplicate():
		if hospital_queue[key]-turns_left >= 2:
			hospital_queue.erase(key)
			key.developments.append(City.DEVELOPMENTS.HOSPITAL)
			icons[cities.find(key)].icon = PARTIAL
	
	if (turns_left == 0):
		end_game()
	#region Totals stuff
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
	#endregion
	on_turn_end.emit(turns_left)


func _on_hospital_button_up() -> void:
	
	select("hospital")
var game_over = false

func _on_ambulance_button_up() -> void:
	
	select("ambulance")


func _on_clinic_button_up() -> void:
	
	select("clinic")


func _on_ads_button_up() -> void:
	
	select("ads")
func select(name):
	if selected == null:
		
		return true
	match name:
		"hospital":
			if (money<hospital_cost):
				show_information("Error", "Not Enough Money")
				selected = null
				return true
			if selected.developments.has(City.DEVELOPMENTS.HOSPITAL):
				selected = null
				show_information("Error", "Can't Build Hospital on City with Hospital")
				return true
			elif hospital_queue.has(selected):
				show_information("Error", "Already Building Hospital")
				return true
			else:
				#selected.developments.append(City.DEVELOPMENTS.HOSPITAL)
				hospital_queue[selected] = turns_left
				money -= hospital_cost
				icons[cities.find(selected)].icon = INPROG
				if selected.developments.has(City.DEVELOPMENTS.CLINIC):
					selected.developments.erase(City.DEVELOPMENTS.CLINIC)
				
		"ambulance":
			if (money<ambulance_cost):
				show_information("Error", "Not Enough Money")
				selected = null
				return true
			if not selected.developments.has(City.DEVELOPMENTS.HOSPITAL):
				selected = null
				show_information("Error", "Ambulances Need a Hospital to Ferry Patients To")
				return true
			elif selected.developments.has(City.DEVELOPMENTS.AMBULANCE):
				selected = null
				show_information("Error", "Can't Add Another Ambulance to City, City is Full")
				return true
			else:
				selected.developments.append(City.DEVELOPMENTS.AMBULANCE)
				money -= ambulance_cost
				ambulance_indexes.append(cities.find(selected))
				icons[cities.find(selected)].icon = DEV
				
		"clinic":
			if (money<clinic_cost):
				show_information("Error", "Not Enough Money")
				selected = null
				return true
			if selected.developments.has(City.DEVELOPMENTS.CLINIC):
				selected = null
				show_information("Error", "Can't Build 2 Clinics on a Single City")
				return true
			if selected.developments.has(City.DEVELOPMENTS.HOSPITAL):
				show_information("Error", "Can't Add A Mobile Clinic to a City with A Hospital")
				return true
			else:
				selected.developments.append(City.DEVELOPMENTS.CLINIC)
				money -= clinic_cost
				icons[cities.find(selected)].icon = CHEAP
		"ads":
			if (money<ads_cost):
				show_information("Error", "Not Enough Money")
				selected = null
				return true
			elif selected.developments.has(City.DEVELOPMENTS.INFORMATION):
				selected = null
				show_information("Error", "Already Information Campaigning on City")
				return true
			else:
				selected.developments.append(City.DEVELOPMENTS.INFORMATION)
				money -= ads_cost
				information_ads[selected] = turns_left
			
	var metric_tween = create_tween().parallel()
	metric_tween.tween_property(self, "displayed_money", money, next_turn_cooldown_timer.wait_time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
				
func cannot_select(name):
	if selected == null:
		
		return true
	match name:
		"hospital":
			if (money<hospital_cost):
				#show_information("Error", "Not Enough Money")
			
				return true
			if selected.developments.has(City.DEVELOPMENTS.HOSPITAL):
			
				#show_information("Error", "Can't Build Hospital on City with Hospital")
				return true
			if hospital_queue.has(selected):
				return true
			elif hospital_queue.has(selected):
				#show_information("Error", "Already Building Hospital")
				return true
				
		"ambulance":
			if (money<ambulance_cost):
				#show_information("Error", "Not Enough Money")
			
				return true
			if not selected.developments.has(City.DEVELOPMENTS.HOSPITAL):
		
				#show_information("Error", "Ambulances Need a Hospital to Ferry Patients To")
				return true
			elif selected.developments.has(City.DEVELOPMENTS.AMBULANCE):
			
				#show_information("Error", "Can't Add Another Ambulance to City, City is Full")
				return true
			
		"clinic":
			if (money<clinic_cost):
				#show_information("Error", "Not Enough Money")
		
				return true
			if selected.developments.has(City.DEVELOPMENTS.CLINIC):
	
				#show_information("Error", "Can't Build 2 Clinics on a Single City")
				return true
			if hospital_queue.has(selected):
				return true
			
		"ads":
			if turns_left >=18:
				return true
			if (money<ads_cost):
				#show_information("Error", "Not Enough Money")
		
				return true
			elif selected.developments.has(City.DEVELOPMENTS.INFORMATION):
	
				#show_information("Error", "Already Information Campaigning on City")
				return true
	return false

func calculate_developments_string_from_selected():
	var string = ""
	if selected.developments.has(City.DEVELOPMENTS.HOSPITAL):
		string += "HOSPITAL\n"
	if selected.developments.has(City.DEVELOPMENTS.AMBULANCE):
		string += "AMBULANCE\n"
	if selected.developments.has(City.DEVELOPMENTS.CLINIC):
		string += "MOB. CLINIC\n"
	if selected.developments.has(City.DEVELOPMENTS.INFORMATION):
		string += "INFORMING\n PUBLIC: \n %d Turns Left\n" % [-information_ads.get(selected)+3+turns_left]
	if string == "":
		return "NONE"
	return string
func city_neighbors_ambulance(city_index):
	var city_row = city_index/6
	var city_column = city_index%6
	for index in ambulance_indexes:
		var index_row = index / 6
		var index_column = index%6
		var row_diff = abs(city_row-index_row)
		var column_diff = abs(city_column-index_column)
		if row_diff+column_diff == 1:
			return true
	return false
func end_game():
	game_over = true
	
	
	

func _on_popup_panel_closed() -> void:
	if game_over:
		get_tree().change_scene_to_file("res://main_menu.tscn")
	if turns_left==20:
		show_tutorial()
