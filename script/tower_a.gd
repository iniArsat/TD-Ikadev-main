extends Node2D

# Variables yang akan di-set dari CSV
var tower_type: String = "Stove_Cannon"
var bullet_speed = 250.0
var bullet_damage = 5.0
var cooldown = 1.0
var range_radius = 150.0
var upgrade_cost_level2 = 50
var upgrade_cost_level3 = 100

# References
var target
var can_shoot = true
@export var bullet_scene: PackedScene
var enemies_in_area : Array = []

@export var max_health := 100.0
var current_health := 0.0
@onready var health_bar: ProgressBar = $HealthBar  
var hide_health_timer := 0.0
var hide_health_delay := 2.0

var is_destroyed := false
var repair_timer := 0.0
var repair_cooldown := 10.0
@onready var repair_label: Label = $RepairLabel
var repair_progress := 0.0
var repair_speed := 10.0

@onready var head: Sprite2D = $Head
@onready var panel_upgrade: Panel = $Panel
@onready var area: Area2D = $Sight
@onready var collision: CollisionShape2D = $Sight/CollisionShape2D
@onready var range_visual: Node2D = $Range_Visual

# Upgrade system
var head_texture_level1: Texture2D
var head_texture_level2: Texture2D
var head_texture_level3: Texture2D
var upgrade_level := 1

var is_dragging = false
# Called when the node enters the scene tree for the first time.
var active_nerfs: Dictionary = {}
var original_cooldown: float = 1.0
var original_accuracy: float = 1.0  # 1.0 = 100% accuracy

func _ready() -> void:
	panel_upgrade.visible = false
	scale = Vector2(1.2, 1.2)
	ClickManager.connect("screen_clicked", Callable(self, "_on_screen_clicked"))
	
	current_health = max_health
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.visible = false
	if repair_label:
		repair_label.visible = false
	if range_visual:
		range_visual.visible = false
		update_range_visual_scale()

func _process(delta: float) -> void:
	if is_dragging:
		return
	if is_destroyed:
		_process_repair(delta)
		return
	if health_bar and health_bar.visible:
		hide_health_timer -= delta
		if hide_health_timer <= 0:
			health_bar.visible = false
			
	_update_nerfs(delta)
		
	if is_instance_valid(target):
		head.look_at(target.global_position)
		head.rotation += deg_to_rad(90)
		if can_shoot:
			_shoot()
	else:
		_update_target()
		
func _process_repair(delta: float):
	repair_timer -= delta
	
	# Isi health secara progressive
	repair_progress += repair_speed * delta
	current_health = min(repair_progress, max_health)
	
	# Update health bar
	if health_bar:
		health_bar.value = current_health
	
	# Update label
	if repair_label:
		var progress_percent = int((current_health / max_health) * 100)
		repair_label.text = "Repair: " + str(progress_percent) + "%"
		repair_label.visible = true
	
	# Jika repair selesai
	if current_health >= max_health:
		_repair_tower()

func update_range_visual_scale():
	if range_visual:
		range_visual.update_radius(range_radius)
		
func _repair_tower():
	is_destroyed = false
	current_health = max_health
	repair_progress = max_health
	
	# Update health bar
	if health_bar:
		health_bar.value = current_health
		health_bar.visible = true
		hide_health_timer = hide_health_delay
	
	# Sembunyikan repair label
	if repair_label:
		repair_label.visible = false
	print("🔧 Tower telah diperbaiki!")
	
# NEW: Fungsi untuk menerima efek nerf
func apply_nerf(nerf_type: String, power: float, duration: float):
	match nerf_type:
		"cooldown":
			# Reduce attack speed (-20%, -30%, etc)
			cooldown = original_cooldown * (1.0 + power)  # power = 0.2 untuk +20% cooldown
		"accuracy":
			# Reduce accuracy (miss rate +25%, etc)
			original_accuracy = max(0.1, 1.0 - power)  # power = 0.25 untuk 25% miss rate
		"mirror_damage":  # BARU
			_apply_mirror_damage(power, duration)
	if nerf_type != "mirror_damage":
		active_nerfs[nerf_type] = {
			"duration": duration,
			"power": power
	}
	
	print("⚠️ Tower kena nerf: ", nerf_type, " selama ", duration, " detik")

# NEW: Update durasi nerf
func _update_nerfs(delta: float):
	for nerf_type in active_nerfs.keys():
		active_nerfs[nerf_type].duration -= delta
		if active_nerfs[nerf_type].duration <= 0:
			_remove_nerf(nerf_type)

# NEW: Hapus efek nerf
func _remove_nerf(nerf_type: String):
	if active_nerfs.has(nerf_type):
		var power = active_nerfs[nerf_type].power
		
		match nerf_type:
			"cooldown":
				cooldown = original_cooldown
			"accuracy":
				original_accuracy = 1.0
		
		active_nerfs.erase(nerf_type)
		print("✅ Nerf ", nerf_type, " telah hilang")

func _shoot():
	if is_destroyed:
		return
	# NEW: Cek accuracy sebelum menembak
	if randf() > original_accuracy:
		print("❌ Tower miss!")
		if is_instance_valid(target) and target.has_method("add_miss"):
			target.add_miss()
		can_shoot = false
		await get_tree().create_timer(cooldown).timeout
		can_shoot = true
		return
	if is_instance_valid(target) and target.has_method("reset_miss"):
		target.reset_miss()
	can_shoot = false
	
	var bullet = bullet_scene.instantiate()
	var aim = $Aim
	
	bullet.global_position = aim.global_position
	bullet.rotation = (target.global_position - aim.global_position).angle()
	
	# Kirim target ke peluru
	bullet.target = target
	bullet.damage = bullet_damage
	bullet.speed = bullet_speed
	
	match tower_type:
		"freeze":
			if bullet.has_method("set_freeze_duration"):
				bullet.set_freeze_duration(2.0)  # 2 detik freeze
		"Pepper_Grinder":  # EFEK BARU
			if bullet.has_method("set_blind_duration"):
				bullet.set_blind_duration(2.5)
				
	get_tree().get_root().add_child(bullet)
	
	await get_tree().create_timer(cooldown).timeout
	can_shoot = true
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		enemies_in_area.append(body)
		if enemies_in_area.size() == 1 and range_visual:
			range_visual.visible = true
		#if enemies_in_area.size() == 1:
			#print("Musuh Terdeteksi")
		if target == null:
			_update_target()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		enemies_in_area.erase(body)
		if body == target:
			_update_target()
		if enemies_in_area.is_empty() and range_visual:
			range_visual.visible = false
		#if enemies_in_area.is_empty():
			#area.visible = false

func _update_target():
	if is_destroyed:
		target = null
		return
	
	if enemies_in_area.size() > 0:
		target = enemies_in_area[0]
	else:
		target = null

#func _on_shape_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	#if event is InputEventMouseButton and event.button_mask == 1: 
		#panel_upgrade.visible = true

func _on_screen_clicked(pos: Vector2) -> void:
	if panel_upgrade.visible:
		var panel_rect = panel_upgrade.get_global_rect()
		# Kalau klik di luar panel → tutup panel
		if not panel_rect.has_point(pos):
			panel_upgrade.visible = false

func _on_texture_button_pressed() -> void:
	var upgrade_cost = get_upgrade_cost()
	if GameManager.coin >= upgrade_cost:
		GameManager.coin -= upgrade_cost
		GameManager.emit_signal("update_coin", GameManager.coin)
		
		upgrade_level += 1
		apply_upgrade_stats()
		print("Tower ", tower_type, " upgraded to level ", upgrade_level)
		
func get_upgrade_cost() -> int:
	match upgrade_level:
		1: return upgrade_cost_level2
		2: return upgrade_cost_level3
		_: return 99999  # Max level

func apply_upgrade_stats():
	match upgrade_level:
		2:
			match tower_type:
				"Stove_Cannon":
					bullet_damage *= 1.5
					cooldown *= 0.9
				"Chilli_Launcher":
					bullet_damage *= 1.8
					range_radius *= 1.2
				"Ice_Chiller":
					cooldown *= 0.7
					bullet_damage *= 1.3
			
			if head_texture_level2:
				head.texture = head_texture_level2             
		3:
			# Level 3 upgrade  
			match tower_type:
				"Stove_Cannon":
					bullet_damage *= 1.5
					cooldown *= 0.9
				"Chilli_Launcher":
					bullet_damage *= 1.8
					range_radius *= 1.2
				"Ice_Chiller":
					cooldown *= 0.7
					bullet_damage *= 1.3
			if head_texture_level3:
				head.texture = head_texture_level3
				
	call_deferred("setup_range_collision")
	call_deferred("update_range_visual_scale")
func _on_texture_button_2_pressed() -> void:
	print("range")


func _on_texture_button_3_pressed() -> void:
	print("damage")
	
func start_drag():
	is_dragging = true
	process_mode = Node.PROCESS_MODE_DISABLED 
	add_to_group("ignore_damage")

func stop_drag():
	is_dragging = false
	process_mode = Node.PROCESS_MODE_INHERIT
	remove_from_group("ignore_damage")

func setup_range_collision():
	# Setup area collision berdasarkan range_radius dari CSV
	if collision and collision.shape is CircleShape2D:
		collision.shape.radius = range_radius
		
func take_damage(damage: float):
	if is_destroyed:
		return
	current_health -= damage
	current_health = max(current_health, 0)
	
	# Update health bar
	if health_bar:
		health_bar.value = current_health
		health_bar.visible = true
		hide_health_timer = hide_health_delay
	
	print("🏗️ Tower menerima damage: ", damage, " | HP: ", current_health, "/", max_health)
	
	if current_health <= 0:
		_destroy_tower()

# NEW: Fungsi tower hancur
func _destroy_tower():
	is_destroyed = true
	repair_timer = repair_cooldown
	repair_progress = 0.0  # Reset progress
	current_health = 0
	can_shoot = false
	target = null

func _apply_mirror_damage(damage_percent: float, duration: float):
	# Tower menerima damage persentase dari max health
	var mirror_damage = max_health * damage_percent
	take_damage(mirror_damage)
	
	# Delay serangan tower
	can_shoot = false  # atau can_activate = false untuk Garlic
	await get_tree().create_timer(duration).timeout
	can_shoot = true   # atau can_activate = true untuk Garlic
	
func setup_from_data(tower_type: String, data: Dictionary):
	self.tower_type = tower_type
	self.bullet_speed = data.get("bullet_speed", 250.0)
	self.bullet_damage = data.get("bullet_damage", 5.0)
	self.cooldown = data.get("cooldown", 1.0)
	self.range_radius = data.get("range_radius", 150.0)
	self.upgrade_cost_level2 = data.get("upgrade_cost_level2", 50)
	self.upgrade_cost_level3 = data.get("upgrade_cost_level3", 100)
	
	original_cooldown = cooldown
	call_deferred("setup_range_collision")
	call_deferred("update_range_visual_scale")
