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

@onready var button_tower_1: Button = $Panel_Encyclopedia/Panel_Tower/FlowContainer/Button
@onready var button_tower_2: Button = $Panel_Encyclopedia/Panel_Tower/FlowContainer/Button2
@onready var button_tower_3: Button = $Panel_Encyclopedia/Panel_Tower/FlowContainer/Button3
@onready var button_tower_4: Button = $Panel_Encyclopedia/Panel_Tower/FlowContainer/Button4
@onready var button_tower_5: Button = $Panel_Encyclopedia/Panel_Tower/FlowContainer/Button5
@onready var panel_tower_info: Panel = $Panel_Encyclopedia/Panel_Tower/Panel
@onready var tower_name_label: Label = $Panel_Encyclopedia/Panel_Tower/Panel/Tower_Name
@onready var tower_desc_label: Label = $Panel_Encyclopedia/Panel_Tower/Panel/Tower_Desc
@onready var tower_stats_label: Label = $Panel_Encyclopedia/Panel_Tower/Panel/Tower_Stats


var tower_data = {
	"Stove_Cannon": {
		"name": "Stove Cannon",
		"description": "Spice Cannon menembakkan peluru rempah dengan akurasi tinggi. 
		Untuk menahan musuh berkecepatan sedang. ",
		"stats": "Tipe: Damage, Single target
		Peran: Tower serangan basic, stabil 
		dan fleksibel "
	},
	"Chilli_Launcher": {
		"name": "Chilli Launcher", 
		"description": "Melontarkan cabai pedas yang dapat mengenai beberapa musuh.
		Efek burn memberikan damage tambahan selama beberapa detik. ",
		"stats": "Tipe: Burn Shot 
		Peran: Serangan cepat, menyerang area"
	},
	"Ice_Chiller": {
		"name": "Ice Chiller",
		"description": "Pendingin dapur yang menyemprotkan es dingin hingga membuat
		musuh membeku sesaat. Efektif untuk memberikan waktu tower lain menyerang",
		"stats": "Tipe: Slow tinggi + Freeze
		Peran: Menahan musuh "
	},
	"Garlic_Tower": {
		"name": "Garlic Tower",
		"description": "Menyebarkan Aroma bawang yang dapat melambatkan musuh diarea. 
		Dapat menjadi penghalang, membuat musuh berjalan lebih lambat ",
		"stats": "Tipe: Slow, Crowd Control 
		Peran: Area Slow, mengurangi kecepatan"
	},
	"Pepper_Grinder": {
		"name": "Pepper Grinder",
		"description": "Penggiling lada yang menembakan lada secara beruntun 
		ke arah musuh sehingga  memperlambat gerakan dan mengurangi akurasi musuh",
		"stats": "Tipe: DPS + High Speed
		Peran: Serangan cepat"
	}
}

func _ready() -> void:
	slider_bgm.value = MusicPlayer.volume
	MusicPlayer.connect("volume_changed", Callable(self, "_on_volume_changed"))
	panel_encyclopedia.visible = false
	GameManager.reset_game()
	GameSpeedManager.reset_speed()
	
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_button_setting_pressed() -> void:
	panel_settings.visible = true


func _on_close_settings_pressed() -> void:
	panel_settings.visible = false
	panel_upgrade.visible = false


func _on_button_level_1_pressed() -> void:
	GameSpeedManager.set_game_speed(1.0)
	GameManager.set_level(1)
	get_tree().change_scene_to_file("res://scene/Main.tscn")

func _on_button_level_2_pressed() -> void:
	GameSpeedManager.set_game_speed(1.0)
	GameManager.set_level(2)
	get_tree().change_scene_to_file("res://scene/main_level2.tscn")

func _on_button_level_3_pressed() -> void:
	GameSpeedManager.set_game_speed(1.0)
	GameManager.set_level(3)
	get_tree().change_scene_to_file("res://scene/main_level3.tscn")

func _on_button_level_4_pressed() -> void:
	GameSpeedManager.set_game_speed(1.0)
	GameManager.set_level(4)
	get_tree().change_scene_to_file("res://scene/main_level4.tscn")
	
func _on_button_level_5_pressed() -> void:
	GameSpeedManager.set_game_speed(1.0)
	GameManager.set_level(5)
	get_tree().change_scene_to_file("res://scene/main_level5.tscn")
	
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
	panel_tower_info.visible = false


func _on_button_tower_pressed() -> void:
	panel_tower.visible = true
	panel_enemies.visible = false
	select_container.visible = false
	close_upgrade.visible = false
	back_upgrade.visible = true
	panel_tower_info.visible = false
	_auto_select_first_tower()

func _on_button_enemies_pressed() -> void:
	panel_tower.visible = false
	panel_enemies.visible = true
	select_container.visible = false
	close_upgrade.visible = false
	back_upgrade.visible = true
	


func _on_close_upgrade_pressed() -> void:
	panel_encyclopedia.visible = false
	panel_tower.visible = false
	panel_enemies.visible = false
	select_container.visible = false

func _on_back_upgrade_pressed() -> void:
	panel_encyclopedia.visible = true
	select_container.visible = true
	close_upgrade.visible = true
	panel_tower.visible = false
	panel_enemies.visible = false
	back_upgrade.visible = false

func _on_tower_button_pressed(tower_type: String):
	if tower_data.has(tower_type):
		var data = tower_data[tower_type]
		tower_name_label.text = data["name"]
		tower_desc_label.text = data["description"]
		tower_stats_label.text = data["stats"]
		panel_tower_info.visible = true
		print("Selected tower: ", data["name"])

func _auto_select_first_tower():
	# Tampilkan info untuk tower pertama
	if tower_data.has("Stove_Cannon"):
		var data = tower_data["Stove_Cannon"]
		tower_name_label.text = data["name"]
		tower_desc_label.text = data["description"]
		tower_stats_label.text = data["stats"]
		panel_tower_info.visible = true
	
	## Highlight button pertama (jika mau visual feedback)
	#if button_tower_1:
		## Simple highlight dengan modulasi warna
		#button_tower_1.modulate = Color(1, 1, 0.5)  # Kuning muda
		#print("Button 1 (Stove Cannon) otomatis terselect")
		
# NEW: Fungsi untuk menutup panel info tower
func _on_close_info_pressed():
	panel_tower_info.visible = false
	
func _on_quit_game_pressed() -> void:
	get_tree().quit()
