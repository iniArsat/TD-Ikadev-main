extends Node

@onready var coin_label = $CanvasLayer/UI_Management/coin_lbl
@onready var score: Label = $CanvasLayer/UI_Management/Victory_Panel/Score
@onready var health_label: Label = $CanvasLayer/UI_Management/health_lbl
@onready var wave_manager = $WaveManager
@onready var countdown_label: Label =$CanvasLayer/UI_Management/Countdown
@onready var ui_upgrade: Panel = $CanvasLayer/UI_Management/Ui_Upgrade
@onready var speed_button: TextureButton = $CanvasLayer/UI_Management/Percepat
@onready var gameover_panel: Panel = $CanvasLayer/UI_Management/Gameover_Panel
@onready var victory_panel: Panel = $CanvasLayer/UI_Management/Victory_Panel
@onready var score_result: Label = $CanvasLayer/UI_Management/Victory_Panel/Score
@onready var wave_lbl: Label = $CanvasLayer/UI_Management/wave_lbl
@onready var pause_panel: Panel = $CanvasLayer/UI_Management/Paused_Panel
@onready var instruction_panel: Panel = $CanvasLayer/UI_Management/Instruction_Panel
#@onready var upgrade_panel: Panel = $CanvasLayer/UI_Management/Upgrade_Panel
@onready var base_sprite: Sprite2D = $Base
@onready var start_wave_button: Button = $CanvasLayer/UI_Management/Start_Wave
@onready var tower_name_label: Label = $CanvasLayer/UI_Management/Ui_Upgrade/Tower_Name_Label
@onready var upgrade_cost_label: Label = $CanvasLayer/UI_Management/Ui_Upgrade/Upgrade_Cost_Label
@onready var upgrade_button: Button = $CanvasLayer/UI_Management/Ui_Upgrade/Upgrade_Button
@onready var close_upgrade: Button = $CanvasLayer/UI_Management/Ui_Upgrade/Close_Upgrade
@export var  countdown:= 15

var game_started = false

@onready var star_1_blank: Sprite2D = $CanvasLayer/UI_Management/Victory_Panel/star_1_blank
@onready var star_1_fill: Sprite2D = $CanvasLayer/UI_Management/Victory_Panel/star_1_fill
@onready var star_2_blank: Sprite2D = $CanvasLayer/UI_Management/Victory_Panel/star_2_blank
@onready var star_2_fill: Sprite2D = $CanvasLayer/UI_Management/Victory_Panel/star_2_fill
@onready var star_3_blank: Sprite2D = $CanvasLayer/UI_Management/Victory_Panel/star_3_blank
@onready var star_3_fill: Sprite2D = $CanvasLayer/UI_Management/Victory_Panel/star_3_fill

var current_tower = null

func _ready() -> void:
	GameSpeedManager.set_game_speed(0.0)
	instruction_panel.visible = true
	ui_upgrade.visible = false
	instruction_panel.instruction_completed.connect(_on_instruction_completed)
	instruction_panel.skip_instructions.connect(_on_skip_instructions)
	
	if start_wave_button:
		start_wave_button.visible = false
		start_wave_button.pressed.connect(_on_start_wave_button_pressed)
		
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
	
	wave_manager.wave_countdown_started.connect(_on_wave_countdown_started)
	wave_manager.wave_countdown_updated.connect(_on_wave_countdown_updated)
	wave_manager.wave_countdown_finished.connect(_on_wave_countdown_finished)
	
	wave_manager.wave_changed.connect(_on_wave_changed)
	speed_button.disabled = true
	
func _on_coins_changed(new_amount: int) -> void:
	coin_label.text = "Coin : " + str(new_amount)
	coin_label.text = str(new_amount)

func _on_health_changed(new_health: int) -> void:
	health_label.text = str(new_health)

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
	if start_wave_button:
		start_wave_button.visible = true
		countdown_label.visible = false
		
func _on_start_wave_button_pressed():
	if start_wave_button:
		start_wave_button.visible = false  # Sembunyikan button
	start_wave_countdown()

func start_wave_countdown():
	countdown_label.visible = true
	await start_initial_countdown(countdown)
	wave_manager.start_next_wave()
	
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
	
	var stars_earned = calculate_stars()
	show_stars(stars_earned)
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
	game_started = false
	
	wave_manager.reset_wave_manager()
	# Hide game over panel
	gameover_panel.visible = false
	victory_panel.visible = false
	
	if base_sprite:
		base_sprite.modulate = Color.WHITE
	# Reset wave manager dan musuh
	get_tree().call_group("player", "queue_free")  # Hapus semua musuh
	get_tree().call_group("tower", "queue_free")
	
	countdown_label.visible = false
	if start_wave_button:
		start_wave_button.visible = true
	GameSpeedManager.set_game_speed(1.0)
	
func _on_restart_button_pressed():
	_reset_game()

func _on_continue_pressed() -> void:
	GameManager.reset_game()
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

func _on_wave_countdown_started(seconds: int):
	countdown_label.visible = true
	countdown_label.text = str(seconds)

func _on_wave_countdown_updated(seconds: int):
	countdown_label.text = str(seconds)

func _on_wave_countdown_finished():
	countdown_label.visible = false
	
func calculate_stars() -> int:
	var health_percentage = float(GameManager.health_player) / 100.0 * 100
	
	if health_percentage >= 100:
		return 3
	elif health_percentage >= 50:
		return 2
	elif health_percentage >= 25:
		return 1
	else:
		return 0

# NEW: Fungsi untuk menampilkan stars di victory panel
func show_stars(stars_count: int):
	# Reset semua stars ke blank terlebih dahulu
	star_1_fill.visible = false
	star_1_blank.visible = true
	star_2_fill.visible = false
	star_2_blank.visible = true
	star_3_fill.visible = false
	star_3_blank.visible = true
	
	# Tampilkan stars sesuai jumlah
	match stars_count:
		3:
			star_1_fill.visible = true
			star_2_fill.visible = true
			star_3_fill.visible = true
			star_1_blank.visible = false
			star_2_blank.visible = false
			star_3_blank.visible = false
		2:
			star_1_fill.visible = true
			star_2_fill.visible = true
			star_3_fill.visible = false
			star_1_blank.visible = false
			star_2_blank.visible = false
			star_3_blank.visible = true
		1:
			star_1_fill.visible = true
			star_2_fill.visible = false
			star_3_fill.visible = false
			star_1_blank.visible = false
			star_2_blank.visible = true
			star_3_blank.visible = true
		0:
			# Semua blank
			star_1_fill.visible = false
			star_2_fill.visible = false
			star_3_fill.visible = false
			star_1_blank.visible = true
			star_2_blank.visible = true
			star_3_blank.visible = true

func show_tower_info(tower_reference):
	current_tower = tower_reference
	ui_upgrade.visible = true
	update_tower_display()

func update_tower_display():
	if current_tower:
		# Update nama tower dan level
		if tower_name_label:
			var display_name = current_tower.tower_type.replace("_", " ")
			tower_name_label.text = display_name + " (Lv." + str(current_tower.upgrade_level) + ")"
		
		# Update cost upgrade
		if upgrade_cost_label:
			var upgrade_cost = current_tower.get_upgrade_cost()
			if upgrade_cost == 99999:
				upgrade_cost_label.text = "MAX LEVEL"
				if upgrade_button:
					upgrade_button.disabled = true
					upgrade_button.text = "MAX LEVEL"
			else:
				upgrade_cost_label.text = "Upgrade: " + str(upgrade_cost) + " coins"
				if upgrade_button:
					upgrade_button.disabled = false
					upgrade_button.text = "UPGRADE"

# FUNGSI UNTUK TOMBOL UPGRADE
func _on_upgrade_button_pressed():
	if current_tower:
		var upgrade_cost = current_tower.get_upgrade_cost()
		
		# Cek apakah coin cukup
		if GameManager.coin >= upgrade_cost:
			# Kurangi coin
			GameManager.coin -= upgrade_cost
			GameManager.emit_signal("update_coin", GameManager.coin)
			
			# Panggil fungsi upgrade di tower
			current_tower.upgrade_tower()
			
			# Update display setelah upgrade
			update_tower_display()
			
			print("Tower upgraded! Current level: ", current_tower.upgrade_level)
		else:
			print("Coin tidak cukup! Butuh ", upgrade_cost, " coin, hanya ada ", GameManager.coin)

func format_tower_name(tower_type: String) -> String:
	match tower_type:
		"Stove_Cannon":
			return "Stove Cannon"
		"Chilli_Launcher":
			return "Chilli Launcher" 
		"Ice_Chiller":
			return "Ice Chiller"
		"Pepper_Grinder":
			return "Pepper Grinder"
		"Garlic":
			return "Garlic Tower"
		_:
			return tower_type.replace("_", " ")

func _on_close_upgrade_panel_pressed():
	ui_upgrade.visible = false
	current_tower = null
	
func _on_quit_pressed() -> void:
	print("quit")

func _on_resume_pressed() -> void:
	GameManager.toggle_pause()

func _on_button_upgrade_pressed() -> void:
	pass
