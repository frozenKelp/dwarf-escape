extends Node
## Manager — application layer
## AUTOLOAD ORDER: AFTER Player and Game.
## asks for Game in _ready(),Game must exist.

enum Screen { MENU, PLAYING, WON, LOST }

signal screen_changed(screen: int)     # emit on swaps screens

var screen := Screen.MENU


func _ready() -> void:
	Game.game_won.connect(_on_won)
	Game.game_over.connect(_on_lost)


## Start (or restart) a run. A Start button / restart button calls this.
## Safe to emit initial values from here: by now the HUD is in the tree and
## listening, so Player.reset() / Game.reset() reach it.
func new_game() -> void:
	Player.reset()
	Game.reset()
	Game.begin()
	_set_screen(Screen.PLAYING)


func restart() -> void:
	new_game()


func quit_to_menu() -> void:
	Game.running = false
	_set_screen(Screen.MENU)


## Clamps to wallet AND debt,
## take mone from Player, record payment in Game. Return amount paid.
func pay_debt(n: int) -> int:
	var amount := mini(n, mini(Player.money, Game.debt))
	if amount <= 0:
		return 0
	Player.spend(amount)
	Game.register_payment(amount)      # reduce debt, count toward quota, check win
	return amount


func _on_won() -> void:
	_set_screen(Screen.WON)


func _on_lost() -> void:
	_set_screen(Screen.LOST)


func _set_screen(s: Screen) -> void:
	screen = s
	screen_changed.emit(s)
