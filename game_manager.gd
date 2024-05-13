extends Node

signal game_over

var player: Player
var player_position: Vector2
var is_game_over: bool = false
var elapsed_time: float = 0.0
var elapsed_time_string: String
var meat_counter: int = 0
var monsters_defeated_counter: int = 0

func _process(delta: float):
	elapsed_time += delta
	var elapsed_time_in_seconds: int = floori(elapsed_time)
	var seconds: int = elapsed_time_in_seconds % 60
	var minutes: int = elapsed_time_in_seconds / 60
	elapsed_time_string = "%02d:%02d" % [minutes, seconds]

func end_game():
	if is_game_over: return
	is_game_over = true
	game_over.emit()
	
func reset():
	player = null
	player_position = Vector2.ZERO
	is_game_over = false
	
	elapsed_time = 0.0
	elapsed_time_string = "00:00"
	meat_counter = 0
	monsters_defeated_counter = 0
	
	for connection in game_over.get_connections():
		game_over.disconnect(connection.callable)
