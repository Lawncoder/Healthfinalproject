extends Resource

class_name Policy

@export_category("Generic")
@export var title = "This is a policy"
@export var description = "It does something"
@export var icon : Image
@export var identifier : String
@export var cost : int = 100
@export var duration : int = 0
@export var popularity_change_per_turn : int = 0
@export var inforcement_cost_per_turn : int= 0

@export_category("Research Attributes")
@export var research_per_turn : int = 0
@export var reveal_clue_per_turn_chance = 0


@export_category("Infection Attributes")
@export var vector_affectiveness := [1.0,1.0,1.0]
@export var infection_rate_multiplier : float = 1
@export var death_rate_multiplier : float = 1
@export var mutation_rate_multiplier : float = 1
@export var city_spread_rate_multiplier : float = 1
