extends Resource

class_name City;

var population = 100;
var infected = 0;
var dead = 0;
var revenue = 0;
var immune = 0;
var developments = []

enum DEVELOPMENTS {
	HOSPITAL, CLINIC, AMBULANCE, INFORMATION
}
