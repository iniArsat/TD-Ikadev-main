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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	slider_bgm.value = MusicPlayer.volume
	MusicPlayer.connect("volume_changed", Callable(self, "_on_volume_changed"))
	panel_encyclopedia.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_button_setting_pressed() -> void:
	panel_settings.visible = true


func _on_close_settings_pressed() -> void:
	panel_settings.visible = false
	panel_upgrade.visible = false


func _on_button_level_1_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/Main.tscn")

func _on_button_level_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/main_level2.tscn")
	
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


func _on_button_tower_pressed() -> void:
	panel_tower.visible = true
	panel_enemies.visible = false
	select_container.visible = false
	close_upgrade.visible = false
	back_upgrade.visible = true

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

func _on_quit_game_pressed() -> void:
	get_tree().quit()
