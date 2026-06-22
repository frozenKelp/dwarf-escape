extends Node2D
@onready var sprite: Sprite2D = $Sprite

const allow_radius = 100

enum STATE { EMPTY, SPIN_UP, HOLD, UNSTABLE } #constants
var state := STATE.EMPTY #CENTRIFUGE STATE
# target band:
var target_min := 12.0
var target_max := 18.0
var progress := 0.00
var instability := 0.00

# gets mouse angular velocity
var last_mouse_position := get_local_mouse_position()
func mAngVel(mouse_position, time):
	var deltaAngle = last_mouse_position.angle_to(mouse_position)
	last_mouse_position = mouse_position
	var mouse_angular_velocity = deltaAngle/time
	print("mouse ang.velocity in rad/sec: ", snapped(mouse_angular_velocity, 0.01)) # snapped is approx
	
#region allowed ring
	if mouse_position.length() < allow_radius:
		last_mouse_position = mouse_position   # avoids a spike on re-entry
		return 0.0 
#endregion
	return mouse_angular_velocity # in rad/sec

# rotates sprite
var aa = 3
var angular_accleration = 3 # radians/sec^2
var angular_velocity = 0 # initial angular vel
func sprite_rotate(mav, time):
	#use higher accleration when stoping for friction feel?
	if abs(angular_velocity) > abs(mav):
		angular_accleration = 2*aa
	else:	
		angular_accleration = aa
	print(angular_accleration)
	angular_velocity = move_toward(angular_velocity, mav, angular_accleration * time)
	sprite.rotation += angular_velocity*time


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
#region set spin state
	var s = abs(angular_velocity)
	if s < target_min:
		state = STATE.SPIN_UP   # "spin faster"
	elif s <= target_max:
		state = STATE.HOLD      # the sweet spot
	else:
		state = STATE.UNSTABLE  # too fast
#endregion

	if state == STATE.HOLD:
		progress += delta
	elif state == STATE.UNSTABLE:
		instability += delta




	var mouse_pos = get_local_mouse_position()
	var mouse_angular_velocity = mAngVel(mouse_pos, delta)
	sprite_rotate(mouse_angular_velocity, delta)
	print(progress,instability)
	
