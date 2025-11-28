extends Node2D

var tower_a = preload("res://scene/tower_a.tscn")
var tower_b = preload("res://scene/tower_B.tscn")
var tower_c = preload("res://scene/tower_C.tscn")

@onready var texture_button: TextureButton = $TextureButton
@onready var panel: Panel = $Panel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Dengarkan sinyal klik global
	ClickManager.connect("screen_clicked", Callable(self, "_on_screen_clicked"))
	
func _spawn_tower(tower_scene : PackedScene):
	var tower = tower_scene.instantiate()	
	tower.global_position = global_position
	get_tree().get_root().get_node("Main/Tower").add_child(tower)
	panel.visible = false


func _on_texture_button_pressed() -> void:
	panel.visible = true
	texture_button.visible = false
	print("Buka Upgrade")

func _on_spawn_a_pressed() -> void:
	var upgrade_cost = 100
	if GameManager.coin >= upgrade_cost:
		GameManager.coin -= upgrade_cost
		GameManager.emit_signal("update_coin", GameManager.coin)
			
		_spawn_tower(tower_a)
	
func _on_spawn_b_pressed() -> void:
	_spawn_tower(tower_b)

func _on_spawn_c_pressed() -> void:
	_spawn_tower(tower_c)

func _on_screen_clicked(pos: Vector2) -> void:
	if panel.visible:
		var panel_rect = panel.get_global_rect()
		# Kalau klik di luar panel → tutup panel
		if not panel_rect.has_point(pos):
			panel.visible = false
			texture_button.visible = true
