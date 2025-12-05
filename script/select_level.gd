extends Control

@onready var panel_settings: Panel = $Panel_Settings
@onready var slider_bgm: HSlider = $Panel_Settings/VBoxContainer/ColorRect/HSlider
@onready var panel_upgrade: Panel = $Panel_Upgrade
@onready var panel_encyclopedia: Panel = $Panel_Encyclopedia
@onready var panel_tower: Panel = $Panel_Encyclopedia/Panel_Tower
@onready var panel_enemies: Panel = $Panel_Encyclopedia/Panel_Enemies
@onready var select_container: HBoxContainer = $Panel_Encyclopedia/Select_Container
@onready var close_upgrade: Button = $Panel_Encyclopedia/Close_Upgrade
@onready var back_upgrade: Button = $Panel_Encyclopedia/Back_Upgrade

# References untuk tombol-tombol tower
@onready var button_tower_1: Button = $Panel_Encyclopedia/Panel_Tower/FlowContainer/Button
@onready var button_tower_2: Button = $Panel_Encyclopedia/Panel_Tower/FlowContainer/Button2
@onready var button_tower_3: Button = $Panel_Encyclopedia/Panel_Tower/FlowContainer/Button3
@onready var button_tower_4: Button = $Panel_Encyclopedia/Panel_Tower/FlowContainer/Button4
@onready var button_tower_5: Button = $Panel_Encyclopedia/Panel_Tower/FlowContainer/Button5
@onready var panel_tower_info: Panel = $Panel_Encyclopedia/Panel_Tower
@onready var tower_name_label: Label = $Panel_Encyclopedia/Panel_Tower/Panel/Tower_Name
@onready var tower_desc_label: Label = $Panel_Encyclopedia/Panel_Tower/Panel/Tower_Desc
@onready var tower_stats_label: Label = $Panel_Encyclopedia/Panel_Tower/Panel/Tower_Stats

# References untuk tombol-tombol enemy
@onready var button_enemy_1: Button = $Panel_Encyclopedia/Panel_Enemies/FlowContainer/Button
@onready var button_enemy_2: Button = $Panel_Encyclopedia/Panel_Enemies/FlowContainer/Button2
@onready var button_enemy_3: Button = $Panel_Encyclopedia/Panel_Enemies/FlowContainer/Button3
@onready var button_enemy_4: Button = $Panel_Encyclopedia/Panel_Enemies/FlowContainer/Button4
@onready var button_enemy_5: Button = $Panel_Encyclopedia/Panel_Enemies/FlowContainer/Button5
@onready var panel_enemy_info: Panel = $Panel_Encyclopedia/Panel_Enemies
@onready var enemy_name_label: Label = $Panel_Encyclopedia/Panel_Enemies/Panel/Tower_Name
@onready var enemy_desc_label: Label = $Panel_Encyclopedia/Panel_Enemies/Panel/Tower_Desc
@onready var enemy_stats_label: Label = $Panel_Encyclopedia/Panel_Enemies/Panel/Tower_Stats
@onready var total_stars_label: Label = $Panel_Upgrade/total_stars

@onready var locked_level_panel: Panel = $Panel_Locked
@onready var ok_button: Button = $Panel_Locked/Button_Oke
@onready var message_label: Label = $Panel_Locked/message_label


# Data untuk setiap tower
var tower_data = {
	"Stove_Cannon": {
		"name": "Stove Cannon",
		"description": "Spice Cannon menembakkan peluru rempah dengan akurasi tinggi. 
		Untuk menahan musuh berkecepatan sedang.",
		"stats": "Tipe: Damage, Single target
		Peran: Tower serangan basic, 
		stabil dan fleksibel",
	},
	"Chilli_Launcher": {
		"name": "Chilli Launcher", 
		"description": "Melontarkan cabai pedas yang dapat mengenai beberapa musuh.
		Efek burn memberikan damage tambahan selama beberapa detik.",
		"stats": "Tipe: Burn Shot
		Peran: Serangan cepat, 
		menyerang area",
	},
	"Ice_Chiller": {
		"name": "Ice Chiller",
		"description": "Pendingin dapur yang menyemprotkan es dingin hingga membuat
		musuh membeku sesaat. Efektif untuk memberikan waktu tower lain 
		menyerang",
		"stats": "Tipe: Slow tinggi + Freeze
		Peran: Menahan musuh ",
	},
	"Garlic_Tower": {
		"name": "Garlic Tower",
		"description": "Menyebarkan Aroma bawang yang dapat melambatkan musuh diarea. 
		Dapat menjadi penghalang, membuat musuh berjalan lebih lambat ",
		"stats": "Tipe: Slow, Crowd Control 
		Peran: Area Slow,
		mengurangi kecepatan",
	},
	"Pepper_Grinder": {
		"name": "Pepper Grinder",
		"description": "Penggiling lada yang menembakan lada secara beruntun ke arah 
		musuh sehingga  memperlambat gerakan dan mengurangi akurasi musuh",
		"stats": "Tipe: DPS + High Speed
		Peran: Serangan cepat ",
	}
}

# Data untuk setiap enemy
var enemy_data = {
	"Grease_Rat": {
		"name": "Grease Rat",
		"description": "Grease Slide: Bergerak lebih cepat dari musuh lain, sulit diprediksi.
		Oily Body: Sedikit mengurangi akurasi beberapa tower 
		(visual: serangan meleset).Swarm Unit: Muncul dalam jumlah 
		banyak untuk “menembus celah tower”.",
		"stats": "HP:  Rendah 
		SPEED:  Tinggi 
		Damage: Rendah "
	},
	"Squirrel_Fire": {
		"name": "Fire Squirrel", 
		"description": "Tupai agresif pembawa bara api, ",
		"stats": "HP:  Sedang 
		SPEED:  Tinggi 
		DAMAGE: Sedang "
	},
	"Monkey": {
		"name": "Monkey",
		"description": "Monkey memiliki tubuh kuat sehingga tidak mudah tumbang oleh serangan 
		kecil. Saat terkena tembakan tower ia akan membalas dengan 
		lemparan rempah, memberikan efek dammage ke tower",
		"stats": "HP: Tinggi 
		SPEED: Sedang  
		DAMAGE: Sedang"
	},
	"Mini_Boss": {
		"name": "Chef Amber",
		"description": "Mini Boss",
		"stats": "HP: Sangat Tinggi  
		SPEED: Sedang
		DAMAGE: Mirror Damage"
	},
	"Blind_Bat": {
		"name": "Chef Baslik",
		"description": "Chef Baslik.",
		"stats": "HP: Sangat Tinggi   
		SPEED:   
		DAMAGE:"
	}
}

var tower_prices = {
	"Garlic_Barrier": 3,    # 10 stars
	"Pepper_Grinder": 5,    # 15 stars
	"Ice_Chiller": 8        # 20 stars
}

var level_requirements = {
	"Garlic_Barrier": 2,  # Level 2
	"Pepper_Grinder": 3,  # Level 3  
	"Ice_Chiller": 4      # Level 4
}

func _ready() -> void:
	slider_bgm.value = MusicPlayer.volume
	MusicPlayer.connect("volume_changed", Callable(self, "_on_volume_changed"))
	panel_encyclopedia.visible = false
	panel_tower_info.visible = false
	panel_enemy_info.visible = false
	locked_level_panel.visible = false
	GameManager.reset_game()
	GameSpeedManager.reset_speed()
	_update_level_buttons()
	_update_total_stars_display()
	_update_store_buttons()
	
	
	if GameManager.should_open_store:
		GameManager.should_open_store = false  # Reset
		call_deferred("_open_store_panel")
	# Connect tombol-tombol tower
	if button_tower_1:
		button_tower_1.pressed.connect(_on_tower_button_pressed.bind("Stove_Cannon"))
	if button_tower_2:
		button_tower_2.pressed.connect(_on_tower_button_pressed.bind("Chilli_Launcher"))
	if button_tower_3:
		button_tower_3.pressed.connect(_on_tower_button_pressed.bind("Garlic_Tower"))
	if button_tower_4:
		button_tower_4.pressed.connect(_on_tower_button_pressed.bind("Pepper_Grinder"))
	if button_tower_5:
		button_tower_5.pressed.connect(_on_tower_button_pressed.bind("Ice_Chiller"))
	
	# Connect tombol-tombol enemy
	if button_enemy_1:
		button_enemy_1.pressed.connect(_on_enemy_button_pressed.bind("Grease_Rat"))
	if button_enemy_2:
		button_enemy_2.pressed.connect(_on_enemy_button_pressed.bind("Squirrel_Fire"))
	if button_enemy_3:
		button_enemy_3.pressed.connect(_on_enemy_button_pressed.bind("Monkey"))
	if button_enemy_4:
		button_enemy_4.pressed.connect(_on_enemy_button_pressed.bind("Mini_Boss"))
	if button_enemy_5:
		button_enemy_5.pressed.connect(_on_enemy_button_pressed.bind("Blind_Bat"))
		

func _update_level_buttons():
	var level_buttons = [
		{"button": $Button_level1, "lock": null, "star_label": $Button_level1/stars_label_1},
		{"button": $Button_level2, "lock": $Button_level2/lock_2, "star_label": $Button_level2/stars_label_2},
		{"button": $Button_level3, "lock": $Button_level3/lock_3, "star_label": $Button_level3/stars_label_3},
		{"button": $Button_level4, "lock": $Button_level4/lock_4, "star_label": $Button_level4/stars_label_4},
		{"button": $Button_level5, "lock": $Button_level5/lock_5, "star_label": $Button_level5/stars_label_5}
	]
	
	for i in range(level_buttons.size()):
		var level = i + 1
		var button = level_buttons[i]["button"]
		var lock = level_buttons[i]["lock"]
		var star_label = level_buttons[i]["star_label"] as Label
		
		if button:
			var is_accessible = SaveManager.is_level_accessible(level)
			var is_completed = SaveManager.is_level_completed(level)
			var stars_count = SaveManager.get_level_stars(level)
			
			button.disabled = not is_accessible
			
			if lock:
				lock.visible = not is_accessible
			
			# Update star label
			if star_label:
				if stars_count > 0:
					star_label.visible = true
					# Tampilkan stars sebagai text: ⭐⭐⭐
					star_label.text = "⭐".repeat(stars_count)
					
					star_label.add_theme_font_size_override("font_size", 84)  # Ukuran font 24px
					
					# GESER POSISI (adjust sesuai kebutuhan)
					# Contoh: Posisi di atas button, center horizontal
					var button_size = button.size
					var label_width = star_label.size.x
					
					# Center horizontal di atas button
					star_label.position.x = (button_size.x - label_width) / 2
					star_label.position.y = 200
				else:
					star_label.visible = false

func _on_buy_ice_pressed():
	_buy_tower("Ice_Chiller", 8)

func _on_buy_garlic_pressed():
	_buy_tower("Garlic_Barrier", 3)

func _on_buy_pepper_pressed():
	_buy_tower("Pepper_Grinder", 5)

func _buy_tower(tower_type: String, price: int):
	var total_stars = SaveManager.save_data["total_stars"]
	
	# Cek sudah punya
	if SaveManager.has_tower(tower_type):
		print("Already own " + tower_type)
		return
	
	# Cek cukup stars
	if total_stars >= price:
		if SaveManager.buy_tower(tower_type):
			# Kurangi stars
			SaveManager.save_data["total_stars"] -= price
			SaveManager.save_game()
			
			print("✅ Purchased " + tower_type + " for " + str(price) + " stars")
			_update_store_buttons()
			_update_total_stars_display()
		else:
			print("❌ Failed to buy " + tower_type)
	else:
		print("❌ Not enough stars! Need: " + str(price) + ", Have: " + str(total_stars))

func _update_store_buttons():
	var highest_level = SaveManager.save_data["highest_level"]
	var total_stars = SaveManager.save_data["total_stars"]
	
	# Update setiap button
	_update_button_state("Garlic_Barrier", highest_level, total_stars)
	_update_button_state("Pepper_Grinder", highest_level, total_stars)
	_update_button_state("Ice_Chiller", highest_level, total_stars)

func _update_button_state(tower_type: String, highest_level: int, total_stars: int):
	var required_level = level_requirements.get(tower_type, 1)
	var price = tower_prices.get(tower_type, 0)
	var has_tower = SaveManager.has_tower(tower_type)
	
	# Cari button berdasarkan nama
	var button = null
	match tower_type:
		"Garlic_Barrier":
			button = $Panel_Upgrade.get_node_or_null("Button_Garlic")
		"Pepper_Grinder":
			button = $Panel_Upgrade.get_node_or_null("Button_Pepper")
		"Ice_Chiller":
			button = $Panel_Upgrade.get_node_or_null("Button_Ice")
	
	if not button:
		return
	
	# Update button berdasarkan kondisi
	if has_tower:
		# Sudah dibeli
		button.text = "✅ OWNED"
		button.disabled = true
	elif highest_level < required_level:
		# Belum unlock level
		button.text = "🔒 Level " + str(required_level)
		button.disabled = true
		button.tooltip_text = "Complete Level " + str(required_level - 1) + " to unlock"
	elif total_stars < price:
		# Level sudah unlock tapi stars kurang
		button.text = "💰 " + str(price) + " ⭐"
		button.disabled = true
		button.tooltip_text = "Need " + str(price) + " stars\nYou have: " + str(total_stars)
	else:
		# Bisa dibeli
		button.text = "BUY - " + str(price) + " ⭐"
		button.disabled = false
		button.tooltip_text = "Click to buy for " + str(price) + " stars"
		
func _update_total_stars_display():
	if total_stars_label:
		var total_stars = SaveManager.get_total_stars()
		total_stars_label.text = str(total_stars)

func _open_store_panel():
	# Pastikan scene sudah siap
	await get_tree().process_frame
	
	# Buka panel store
	$Panel_Upgrade.visible = true
	
func _on_button_setting_pressed() -> void:
	panel_settings.visible = true

func _on_close_settings_pressed() -> void:
	panel_settings.visible = false
	panel_upgrade.visible = false

func _on_button_level_1_pressed() -> void:
	_start_level(1, "res://scene/Main.tscn")

func _on_button_level_2_pressed() -> void:
	_start_level(2, "res://scene/main_level2.tscn")

func _on_button_level_3_pressed() -> void:
	_start_level(3, "res://scene/main_level3.tscn")

func _on_button_level_4_pressed() -> void:
	_start_level(4, "res://scene/main_level4.tscn")
	
func _on_button_level_5_pressed() -> void:
	_start_level(5, "res://scene/main_level5.tscn")

func _start_level(level: int, scene_path: String):
	if SaveManager.is_level_accessible(level):
		GameSpeedManager.set_game_speed(1.0)
		GameManager.set_level(level)
		get_tree().change_scene_to_file(scene_path)
	else:
		print("🔒 Level ", level, " locked!")
		_show_locked_panel(level)

func _show_locked_panel(level: int):
	# Tampilkan panel terkunci
	locked_level_panel.visible = true
	
	if message_label:
		message_label.text = "Level " + str(level) + " terkunci!\nSelesaikan level " + str(level-1) + " terlebih dahulu."
func _on_ok_button_pressed() -> void:
	locked_level_panel.visible = false

func _on_button_reset_pressed() -> void:
	var dialog = ConfirmationDialog.new()
	dialog.title = "Reset Progress"
	dialog.dialog_text = "Yakin ingin menghapus semua progress?\nSemua level yang terbuka akan dikunci kembali."
	dialog.confirmed.connect(_confirm_reset)
	
	add_child(dialog)
	dialog.popup_centered()

func _confirm_reset():
	SaveManager.reset_progress()
	_update_level_buttons()
	_update_total_stars_display()
	print("🔄 All progress reset")
	
func _on_slider_bgm_value_changed(value: float) -> void:
	MusicPlayer.set_bgm_volume(value)
	
func _on_volume_changed(value):
	# update slider jika diperlukan
	if slider_bgm.value != value:
		slider_bgm.value = value

func _on_button_upgrade_pressed() -> void:
	panel_upgrade.visible = true

func _on_button_encyclopedia_pressed() -> void:
	panel_encyclopedia.visible = true
	select_container.visible = true
	close_upgrade.visible = true
	# Sembunyikan panel info saat masuk encyclopedia
	panel_tower_info.visible = false
	panel_enemy_info.visible = false

func _on_button_tower_pressed() -> void:
	panel_tower.visible = true
	panel_enemies.visible = false
	select_container.visible = false
	close_upgrade.visible = false
	back_upgrade.visible = true
	
	# Otomatis select button pertama saat panel tower dibuka
	call_deferred("_auto_select_default_tower")

func _auto_select_default_tower():
	# Tampilkan info untuk Stove Cannon (button pertama)
	if button_tower_1 and tower_data.has("Stove_Cannon"):
		var data = tower_data["Stove_Cannon"]
		tower_name_label.text = data["name"]
		tower_desc_label.text = data["description"]
		tower_stats_label.text = data["stats"]
		panel_tower_info.visible = true
		print("📌 Tower 'Stove Cannon' otomatis terselect")

func _on_button_enemies_pressed() -> void:
	panel_tower.visible = false
	panel_enemies.visible = true
	select_container.visible = false
	close_upgrade.visible = false
	back_upgrade.visible = true
	
	# Otomatis select button pertama saat panel enemy dibuka
	call_deferred("_auto_select_default_enemy")

func _auto_select_default_enemy():
	# Tampilkan info untuk Grease Rat (button pertama)
	if button_enemy_1 and enemy_data.has("Grease_Rat"):
		var data = enemy_data["Grease_Rat"]
		enemy_name_label.text = data["name"]
		enemy_desc_label.text = data["description"]
		enemy_stats_label.text = data["stats"]
		panel_enemy_info.visible = true
		print("👾 Enemy 'Grease Rat' otomatis terselect")

func _on_close_upgrade_pressed() -> void:
	panel_encyclopedia.visible = false
	panel_tower.visible = false
	panel_enemies.visible = false
	select_container.visible = false
	panel_tower_info.visible = false
	panel_enemy_info.visible = false

func _on_back_upgrade_pressed() -> void:
	panel_encyclopedia.visible = true
	select_container.visible = true
	close_upgrade.visible = true
	panel_tower.visible = false
	panel_enemies.visible = false
	back_upgrade.visible = false
	panel_tower_info.visible = false
	panel_enemy_info.visible = false

# Fungsi untuk tombol tower individu
func _on_tower_button_pressed(tower_type: String):
	if tower_data.has(tower_type):
		var data = tower_data[tower_type]
		tower_name_label.text = data["name"]
		tower_desc_label.text = data["description"]
		tower_stats_label.text = data["stats"]
		panel_tower_info.visible = true
		print("Selected tower: ", data["name"])

# Fungsi untuk tombol enemy individu
func _on_enemy_button_pressed(enemy_type: String):
	if enemy_data.has(enemy_type):
		var data = enemy_data[enemy_type]
		enemy_name_label.text = data["name"]
		enemy_desc_label.text = data["description"]
		enemy_stats_label.text = data["stats"]
		panel_enemy_info.visible = true
		print("Selected enemy: ", data["name"])

# Fungsi untuk menutup panel info tower
func _on_close_tower_info_pressed():
	panel_tower_info.visible = false

# Fungsi untuk menutup panel info enemy
func _on_close_enemy_info_pressed():
	panel_enemy_info.visible = false

func _on_button_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
	
func _on_quit_game_pressed() -> void:
	get_tree().quit()
