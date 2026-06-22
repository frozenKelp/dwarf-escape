extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



func _process(delta: float) -> void:
	print("velocity: ", say_vel(delta))
	
var oldangle = self.rotation
func say_vel(time):
	var angle = self.rotation
	var angledelta =  angle - oldangle
	var velocity = snapped(angledelta/time, 0.01)
	
	oldangle = angle
	return velocity
