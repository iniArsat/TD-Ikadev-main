extends Node2D


var coin: int = 10000
var health_player: int = 100
 
signal update_coin(new_amount: int)
signal update_health(new_amount: int)
signal game_over()
signal base_damaged()
var invalid_drop_areas: Array = []
var valid_drop_areas: Array = []
var is_game_over = false
var placed_towers: Array = []  # Menyimpan referensi semua tower yang sudah terpasang
var min_tower_distance: float = 80.0 

func _add_coin(amount: int) -> void:
	coin += amount
	emit_signal("update_coin", coin)
	
func _take_damage(amount: int) -> void:
	if is_game_over:
		return
		
	health_player -= amount
	emit_signal("update_health", health_player)
	emit_signal("base_damaged")
	
	if health_player <= 0:
		_game_over()

func toggle_game_speed():
	GameSpeedManager.toggle_speed()
	
func toggle_pause():
	GameSpeedManager.toggle_pause()
# Fungsi untuk mendapatkan status speed
func is_fast_forward() -> bool:
	return GameSpeedManager.is_fast_forward()
	
func is_game_paused() -> bool:
	return GameSpeedManager.is_game_paused()

func reset_game():
	coin = 10000
	health_player = 100
	is_game_over = false
	placed_towers.clear()
	GameSpeedManager.reset_speed()
	emit_signal("update_coin", coin)
	emit_signal("update_health", health_player)
	
func _game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	GameSpeedManager.set_game_speed(0.0)  # NEW: Pause game
	emit_signal("game_over")
	print("GameOver")
	
