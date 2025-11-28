extends Node2D

var target
var can_shoot = true
@export var bullet_speed = 250.0
@export var bullet_damage = 5.0
var bullet_scene = preload("res://scene/bullet.tscn")

var enemies_in_area : Array = []

@onready var head: Sprite2D = $Head
@onready var panel: Panel = $Panel
@onready var area: Panel = $Area


var is_dragging = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	panel.visible = false
	ClickManager.connect("screen_clicked", Callable(self, "_on_screen_clicked"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_dragging:
		return
		
	if is_instance_valid(target):
		head.look_at(target.global_position)
		head.rotation += deg_to_rad(90)
		if can_shoot:
			_shoot()
	else:
		_update_target()

func _shoot():
	can_shoot = false
	
	var bullet = bullet_scene.instantiate()
	var aim = $Aim
	
	bullet.global_position = aim.global_position
	bullet.rotation = (target.global_position - aim.global_position).angle()
	
	# Kirim target ke peluru
	bullet.target = target
	bullet.damage = bullet_damage
	bullet.speed = bullet_speed
	
	
	get_tree().get_root().add_child(bullet)
	
	await get_tree().create_timer(1.0).timeout
	can_shoot = true
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("masuk")
		enemies_in_area.append(body)
		if body == target:
			_update_target()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		enemies_in_area.erase(body)
		if body == target:
			_update_target()

func _update_target():
	if enemies_in_area.size()>0:
		target = enemies_in_area[0]
	else:
		target = null

func _on_shape_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_mask == 1: 
		panel.visible = true

func _on_screen_clicked(pos: Vector2) -> void:
	if panel.visible:
		var panel_rect = panel.get_global_rect()
		# Kalau klik di luar panel → tutup panel
		if not panel_rect.has_point(pos):
			panel.visible = false


func _on_texture_button_pressed() -> void:
	var upgrade_cost = 10
	if GameManager.coin >= upgrade_cost:
		GameManager.coin -= upgrade_cost
		GameManager.emit_signal("update_coin", GameManager.coin)
		bullet_speed += 10
		bullet_damage += 5

func _on_texture_button_2_pressed() -> void:
	print("range")


func _on_texture_button_3_pressed() -> void:
	print("damage")
	
func start_drag():
	is_dragging = true
	area.visible = true
	process_mode = Node.PROCESS_MODE_DISABLED 

func stop_drag():
	is_dragging = false
	area.visible = false
	process_mode = Node.PROCESS_MODE_INHERIT
