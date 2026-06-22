extends Node2D
@onready var sprite: Sprite2D = $Sprite

const allow_radius = 100

enum STATE { EMPTY, SPIN_UP, HOLD, UNSTABLE, STOP } #constants
var state := STATE.EMPTY #CENTRIFUGE STATE
# target band:
@export var target_min := 9.0
@export var target_max := 16.0

var progress := 0.00
@export var progress_multiplier := 6
var instability := 0.00
@export var instablity_multiplier := 20

# gets mouse angular velocity
var last_mouse_position := get_local_mouse_position()
func mAngVel(mouse_position, time):
	var deltaAngle = last_mouse_position.angle_to(mouse_position)
	last_mouse_position = mouse_position
	var mouse_angular_velocity = deltaAngle/time
	print("mouse ang.velocity in rad/sec: ", snapped(mouse_angular_velocity, 0.01)) # snapped is approx
	#region allowed ring
	if mouse_position.length() < allow_radius or state == STATE.STOP:
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

func stop():
	pass
func hold(t):
	progress += t*progress_multiplier
func unstable(t):
	instability += t*instablity_multiplier
func spin():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
#region set spin state
	if progress >= 100 or instability >= 100:
		state = STATE.STOP
	else:
		var s = abs(angular_velocity)
		if s < target_min:
			state = STATE.SPIN_UP   # "spin faster"
		elif s <= target_max:
			state = STATE.HOLD      # the sweet spot
		else:
			state = STATE.UNSTABLE  # too fast
#endregion

#region state process
	if state == STATE.HOLD:
		hold(delta)
	elif state == STATE.UNSTABLE:
		unstable(delta)
	elif state == STATE.STOP:
		stop()
#endregion

	var mouse_pos = get_local_mouse_position()
	var mouse_angular_velocity = mAngVel(mouse_pos, delta)
	sprite_rotate(mouse_angular_velocity, delta)
	
	print("progress: ", snapped(progress, 0.1),"instability: ", snapped(instability, 0.1))
	
