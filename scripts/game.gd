extends Node
## Game — the run state:

signal debt_changed(value: int)
signal week_changed(week: int, quota: int)
signal quota_warning()                 # fires once, near the weekly deadline
signal game_won()                      # debt cleared OR slot jackpot
signal game_over()                     # missed the weekly quota

# --- CONSTANTS (balance the game later, pls) ---
const STARTING_DEBT := 9999
const STARTING_QUOTA := 100
const QUOTA_GROWTH := 1.3              # quota multiplies by this each new week
const WEEK_LENGTH := 150.0             # seconds per in-game week
const WARNING_TIME := 10.0             # seconds left when the alarm fires

const PRICE := {                       # base sell price per refined type
	"iron": 10,
	"frost_iron": 50,
}

# --- state ---
var debt: int
var quota: int                         # minimum that must be paid this week
var paid_this_week: int                # accumulates every payment this week
var week: int
var week_time_left: float
var running: bool = false              # the clock only ticks while this is true
var _warned: bool


func _ready() -> void:
	reset()


## Wipe to a fresh run, clock stopped. Manager.new_game() calls this, then begin().
func reset() -> void:
	debt = STARTING_DEBT
	quota = STARTING_QUOTA
	paid_this_week = 0
	week = 1
	week_time_left = WEEK_LENGTH
	_warned = false
	running = false
	debt_changed.emit(debt)
	week_changed.emit(week, quota)


## Start the weekly clock, once the run begins.
func begin() -> void:
	running = true


# --- weekly clock ---
func _process(delta: float) -> void:
	if not running:
		return
	week_time_left -= delta
	if week_time_left <= WARNING_TIME and not _warned:
		_warned = true
		quota_warning.emit()
	if week_time_left <= 0.0:
		_resolve_week()


func _resolve_week() -> void:
	if paid_this_week >= quota:
		_advance_week()
	else:
		running = false
		game_over.emit()


func _advance_week() -> void:
	week += 1
	quota = roundi(quota * QUOTA_GROWTH)
	paid_this_week = 0
	week_time_left = WEEK_LENGTH
	_warned = false
	week_changed.emit(week, quota)


## Records debt payment. Manager.pay_debt() calls this AFTER taking the money from Player.
func register_payment(amount: int) -> void:
	debt -= amount
	paid_this_week += amount
	debt_changed.emit(debt)
	if debt <= 0:
		win()


## Ends the run in victory. Called at zero debt, and on jackpot.
func win() -> void:
	running = false
	game_won.emit()
