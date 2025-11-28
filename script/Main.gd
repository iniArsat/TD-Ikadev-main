extends Node

@onready var coin_label = $CanvasLayer/UI_Management/coin_lbl
@onready var score: Label = $CanvasLayer/UI_Management/Victory_Panel/Score
@onready var health_label: Label = $CanvasLayer/UI_Management/health_lbl
@onready var wave_manager = $WaveManager
@onready var countdown_label: Label =$CanvasLayer/UI_Management/Countdown
@onready var ui_upgrade: Panel = $CanvasLayer/UI_Management/Panel
@onready var speed_button: TextureButton = $CanvasLayer/UI_Management/Percepat
@onready var gameover_panel: Panel = $CanvasLayer/UI_Management/Gameover_Panel
@onready var victory_panel: Panel = $CanvasLayer/UI_Management/Victory_Panel
@onready var score_result: Label = $CanvasLayer/UI_Management/Victory_Panel/Score
@onready var wave_lbl: Label = $CanvasLayer/UI_Management/wave_lbl
@onready var pause_panel: Panel = $CanvasLayer/UI_Management/Paused_Panel
@onready var instruction_panel: Panel = $CanvasLayer/UI_Management/Instruction_Panel
#@onready var upgrade_panel: Panel = $CanvasLayer/UI_Management/Upgrade_Panel
@onready var base_sprite: Sprite2D = $Base

@export var  countdown:= 15



func _ready() -> void:
	GameSpeedManager.set_game_speed(0.0)
	instruction_panel.visible = true
	instruction_panel.instruction_completed.connect(_on_instruction_completed)
	instruction_panel.skip_instructions.connect(_on_skip_instructions)
	
	GameManager.update_coin.connect(_on_coins_changed)
	_on_coins_changed(GameManager.coin) # tampilkan nilai awal
	GameManager.update_health.connect(_on_health_changed)
	_on_health_changed(GameManager.health_player)
	GameManager.invalid_drop_areas = get_tree().get_nodes_in_group("invalid_drop_area")
	GameManager.valid_drop_areas = get_tree().get_nodes_in_group("valid_drop_area")
	GameManager.base_damaged.connect(flash_base_simple)
	
	GameSpeedManager.game_speed_changed.connect(_on_game_speed_changed)
	GameSpeedManager.game_paused.connect(_on_game_paused)
	GameManager.game_over.connect(_on_game_over)
	wave_manager.victory_achieved.connect(_on_victory_achieved)
	gameover_panel.visible = false
	
	wave_manager.wave_changed.connect(_on_wave_changed)
	speed_button.disabled = true
	
	await start_initial_countdown(countdown)
	wave_manager.start_next_wave()
	
func _on_coins_changed(new_amount: int) -> void:
	coin_label.text = "Coin : " + str(new_amount)
	coin_label.text = str(new_amount)

func _on_health_changed(new_health: int) -> void:
	health_label.text = "Health : " + str(new_health)

func _on_speed_button_pressed():
	GameManager.toggle_game_speed()

# NEW: Fungsi untuk handle game speed change
func _on_game_speed_changed(speed_multiplier: float):
	_update_speed_button_text()
	
func _on_instruction_completed():
	instruction_panel.visible = false
	_start_game()

func _on_skip_instructions():
	instruction_panel.visible = false
	_start_game()
	
func _start_game():
	GameSpeedManager.set_game_speed(1.0)
	speed_button.disabled = false
	await start_initial_countdown(countdown)
	wave_manager.start_next_wave()
# NEW: Update text button speed
func _update_speed_button_text():
	print("speed x2")
	#if speed_button:
		#if GameSpeedManager.is_fast_forward():
			#speed_button.text = "Speed: 2x"
		#else:
			#speed_button.text = "Speed: 1x"
			
func start_initial_countdown(seconds: int) -> void:
	countdown_label.visible = true
	
	for i in range(seconds, 0, -1):
		countdown_label.text = str(i)
		await get_tree().create_timer(1.0).timeout
	
	await get_tree().create_timer(.0).timeout
	countdown_label.visible = false

func _on_upgrade_button_pressed() -> void:
	ui_upgrade.visible = not ui_upgrade.visible

func _input(event):
	if event.is_action_pressed("toggle_speed"):
		_on_speed_button_pressed()
	if event.is_action_pressed("ui_cancel"):  # Escape key
		_on_pause_pressed()
		
func _on_game_over():
	gameover_panel.visible = true
	score.text = str(GameManager.coin)

func _on_victory_achieved():
	victory_panel.visible = true
	score_result.text = str(GameManager.coin)
	# Pause game
	GameSpeedManager.set_game_speed(0.0)
	print("🎉 Victory! Semua wave berhasil dikalahkan!")

func flash_base_simple():
	if not base_sprite:
		return
	
	var tween = create_tween()
	tween.tween_property(base_sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(base_sprite, "modulate", Color.WHITE, 0.1)
	tween.tween_property(base_sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(base_sprite, "modulate", Color.WHITE, 0.1)
	
func _on_wave_changed(current_wave: int, total_waves: int):
	if wave_lbl:
		wave_lbl.text = "%d/%d" % [current_wave, total_waves]
		
func _reset_game():
	GameManager.reset_game()
	
	wave_manager.reset_wave_manager()
	# Hide game over panel
	gameover_panel.visible = false
	victory_panel.visible = false
	
	if base_sprite:
		base_sprite.modulate = Color.WHITE
	# Reset wave manager dan musuh
	get_tree().call_group("player", "queue_free")  # Hapus semua musuh
	get_tree().call_group("tower", "queue_free")
	
	# Start game baru
	await start_initial_countdown(countdown)
	wave_manager.start_next_wave()
	
func _on_restart_button_pressed():
	await _reset_game()

func _on_continue_pressed() -> void:
	GameSpeedManager.set_game_speed(1.0)
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://scene/select_level.tscn")

func _on_pause_pressed() -> void:
	GameManager.toggle_pause()
	
func _on_game_paused(is_paused: bool):
	if is_paused:
		pause_panel.visible = true
	else:
		pause_panel.visible = false

func _on_main_menu_pressed() -> void:
	GameSpeedManager.set_game_speed(1.0)  # Reset speed
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")

func _on_quit_pressed() -> void:
	print("quit")

func _on_resume_pressed() -> void:
	GameManager.toggle_pause()

func _on_button_upgrade_pressed() -> void:
	pass
