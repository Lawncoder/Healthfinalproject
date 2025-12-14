extends Resource

class_name Pathogen

@export var number_of_turns_held = 3
@export var death_rate = 0.2
@export var city_spread_rate = 0.2 #per person infected to infect a person from another city
@export var infection_rate = 1 #how many people is the pathogen spread to per turn
@export var mutation_chance = 0.01;
@export var attack_vector = Vectors.AIR

enum Vectors {
	WATER, TOUCH, AIR, FOOD 
	#TODO: implement environmental issues that affect each of the four vectors, implement policies that hinder a pathogen of each of the four vectors
}
