extends Node
## Player state: the wallet and inventory
#### autoload
## NOTE: DATA script , separate from the on-screen character.
## Name that "Dwarf" so the identifier `Player` always referes to this script.


signal money_changed(value: int)
signal inventory_changed()

var money: int
var ore: Dictionary        # { "iron": 3, "copper": 1 } etc
var refined: Array         # [ { "type": "frost_iron", "quality": 0.82 }, ... ]
var upgrades: Dictionary   # { "wide_band": true, "fast_spinup": 2 }


func _ready() -> void:
	reset()

## Wipe DATA for fresh run. Manager.new_game() calls this.
func reset() -> void:
	money = 0
	ore = {}
	refined = []
	upgrades = {}
	money_changed.emit(money)
	inventory_changed.emit()


# --- money ---
func add_money(n: int) -> void:
	money += n
	money_changed.emit(money)



func spend(n: int) -> bool:
	if money < n:
		return false ## Returns false if you can't afford it, poor pleb!
	money -= n
	money_changed.emit(money)
	return true


# --- ore ---
func add_ore(type: String, n: int = 1) -> void:
	ore[type] = ore.get(type, 0) + n
	inventory_changed.emit()



func consume_ore(type: String, n: int = 1) -> bool:
	if ore.get(type, 0) < n:
		return false ## Returns false if there isn't enough — the feeder checks this before loading.
	ore[type] -= n
	if ore[type] <= 0:
		ore.erase(type)
	inventory_changed.emit()
	return true


# --- refined metal (each batch keeps its own quality) ---
func add_refined(type: String, quality: float) -> void:
	refined.append({ "type": type, "quality": clampf(quality, 0.0, 1.0) })
	inventory_changed.emit()


## Sells one batch by index, priced by its quality. Returns the gold earned.
func sell_refined(index: int) -> int:
	if index < 0 or index >= refined.size():
		return 0
	var batch: Dictionary = refined.pop_at(index)
	# Market price lives on Game
	var value: int = roundi(float(Game.PRICE.get(batch.type, 0)) * batch.quality)
	add_money(value)
	inventory_changed.emit()
	return value


func sell_all_refined() -> int:
	var total := 0
	while refined.size() > 0:
		total += sell_refined(0)
	return total


# --- upgrades (stations read these to modify their behaviour) ------=---=-__--
func has_upgrade(key: String) -> bool:
	return upgrades.get(key, false) != false


func get_upgrade(key: String, default = 0):
	return upgrades.get(key, default)


## Buys/sets an upgrade if affordable and not already owned. Returns success.
func buy_upgrade(key: String, cost: int, value = true) -> bool:
	if upgrades.get(key, null) == value:
		return false                   # already owned at this level
	if not spend(cost):
		return false
	upgrades[key] = value
	inventory_changed.emit()
	return true
