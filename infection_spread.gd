extends Line2D

var anim_time = 0.75;
var pointA:Vector2
var pointB:Vector2

var distance;
var step_distance
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	distance = pointA.distance_to(pointB)
	step_distance = distance/anim_time
	add_point(pointA)
	add_point(pointA)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	remove_point(0)
	var new_point = pointB - points[0]
	new_point = new_point.normalized()
	add_point(new_point * step_distance*delta + points[0])
	anim_time -= delta
	if anim_time<=0:
		queue_free()
	
