extends Node2D
## Centrifuge — load ore in the feeder, spin the cast and HOLD it in the target
## velocity range refine it; overspin and smelter turns UNSTABLE and the batch is ruined.
## Stop the spin to eject the result.

@onready var sprite: Sprite2D = $Sprite

signal refined(metal: String, quality: float)   # success: a finished batch pops out
signal batch_ruined()                            # failure: overspun, lost the batch
signal state_changed(new_state: int)             # STATE enum value, for HUD/audio

const allow_radius := 100.0

enum STATE { EMPTY, SPIN_UP, HOLD, UNSTABLE, STOP }
var state := STATE.EMPTY

# target speed band (rad/sec of the flywheel)
@export var target_min := 9.0
@export var target_max := 16.0

# refining accumulators (0..100)
@export var progress_multiplier := 10
@export var progress_cooldown := 2
@export var instability_multiplier := 20
@export var instability_cooldown := 3          # instability reduces per sec while not overspun
var progress := 0.0
var instability := 0.0

@export var loaded := ""                                 # what's being refined; "" = empty

# flywheel
@export var accel := 4.0                          # rad/sec^2
var angular_velocity := 0.0
var last_mouse_position: Vector2


func _ready() -> void:
	last_mouse_position = get_local_mouse_position()


## Load a metal to refine.
## NOTE: consume the ore from Player first, then call this.
## Returns false if the centrifuge is busy.
func feed(metal: String) -> bool:
	if state != STATE.EMPTY:
		return false
	loaded = metal
	progress = 0.0
	instability = 0.0
	return true


func _process(delta: float) -> void:
	_update_state()
	_accumulate(delta)
	_spin(delta)
	_check_eject()
	print(state)
	print("progress: ", progress)
	print("instablity: ", instability)


# --- machine state ---
func _update_state() -> void:
	var next := state
	if loaded == "":
		next = STATE.EMPTY                      # set empty if not
	elif progress >= 100.0 or instability >= 100.0:
		next = STATE.STOP
	else:
		var s := absf(angular_velocity)
		if s < target_min:
			next = STATE.SPIN_UP                 # spin faster
		elif s <= target_max:
			next = STATE.HOLD                    # sweet spot
		else:
			next = STATE.UNSTABLE                # too fast
	if next != state:                            # set decided state
		state = next
		state_changed.emit(state)


func _accumulate(delta: float) -> void:
	match state:
		STATE.HOLD:
			progress += delta * progress_multiplier
			instability = maxf(0.0, instability - delta * instability_cooldown)
		STATE.SPIN_UP:
			instability = maxf(0.0, instability - delta * instability_cooldown)
			progress = maxf(0.0, progress - delta * progress_cooldown)
		STATE.UNSTABLE:
			instability += delta * instability_multiplier
			progress = maxf(0.0, progress - delta * progress_cooldown)


# --- flywheel ---
func _spin(delta: float) -> void:
	var mav := _mouse_ang_vel(get_local_mouse_position(), delta)
	# friction , brake faster than you accelerate
	var a := accel * (1.8 if absf(angular_velocity) > absf(mav) else 1.0)
	angular_velocity = move_toward(angular_velocity, mav, a * delta)
	sprite.rotation += angular_velocity * delta


## Mouse angular velocity around centre. Returns 0 inside the dead zone, or while STOPping.
func _mouse_ang_vel(mouse_position: Vector2, time: float) -> float:
	if mouse_position.length() < allow_radius or state == STATE.STOP or state == STATE.EMPTY:
		last_mouse_position = mouse_position     # avoids a spike on re-entry
		return 0.0
	var delta_angle := last_mouse_position.angle_to(mouse_position)
	last_mouse_position = mouse_position
	return delta_angle / time


# --- finishing ---
func _check_eject() -> void:
	# once the wheel has come to rest, collect the result
	if state == STATE.STOP and is_zero_approx(angular_velocity):
		_eject()


func _eject() -> void:
	if progress >= 100.0:
		refined.emit(loaded, quality())
	else:
		batch_ruined.emit()
	loaded = ""
	progress = 0.0
	instability = 0.0
	state = STATE.EMPTY
	state_changed.emit(state)


## 0..1. A clean hold = 1.0; time spent UNSTABLE taxes it.
func quality() -> float:
	return clampf(1.0 - instability / 100.0, 0.0, 1.0)
