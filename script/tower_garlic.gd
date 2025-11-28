extends Node2D
class_name GarlicTower

# Variables dari CSV
var tower_type: String = "Garlic_Tower"
var bullet_speed = 0.0
var bullet_damage = 0.0
var cooldown = 5.0
var range_radius = 200.0
var upgrade_cost_level2 = 80
var upgrade_cost_level3 = 160

# Slow properties
var slow_power := 0.5   # 50% slow
var slow_duration := 3.0
var is_aura_active := false
var can_activate := true

# References
@onready var aura: Sprite2D = $Aura_Effect
@onready var area: Area2D = $Sight
@onready var collision: CollisionShape2D = $Sight/CollisionShape2D
@onready var panel_upgrade: Panel = $Panel
@onready var range_visual: RangeVisual = $Range_Visual

@export var max_health := 100.0
var current_health := 0.0
@onready var health_bar: ProgressBar = $HealthBar
var hide_health_timer := 0.0
var hide_health_delay := 2.0

# Destruction system
var is_destroyed := false
var repair_timer := 0.0
var repair_cooldown := 10.0
@onready var repair_label: Label = $RepairLabel
var repair_progress := 0.0
var repair_speed := 10.0
# Upgrade system
var upgrade_level := 1
var enemies_in_area: Array = []
var currently_slowed_enemies: Array = []  # Track musuh yang sedang di-slow
var active_nerfs: Dictionary = {}
var original_cooldown: float = 5.0

func _ready() -> void:
	aura.visible = false
	panel_upgrade.visible = false
	ClickManager.connect("screen_clicked", Callable(self, "_on_screen_clicked"))
	setup_range_collision()
	
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

func update_range_visual_scale():
	if range_visual:
		range_visual.update_radius(range_radius)
		
func setup_range_collision():
	if collision and collision.shape is CircleShape2D:
		collision.shape.radius = range_radius

func _process(delta: float) -> void:
	if is_destroyed:
		_process_repair(delta)
		return
		
	if health_bar and health_bar.visible:
		hide_health_timer -= delta
		if hide_health_timer <= 0:
			health_bar.visible = false
	if can_activate and enemies_in_area.size() > 0:
		_activate_aura()
	if range_visual:
		if enemies_in_area.size() > 0 and not range_visual.visible:
			range_visual.visible = true
		elif enemies_in_area.size() == 0 and range_visual.visible:
			range_visual.visible = false

func _activate_aura():
	if not can_activate:
		return
	
	can_activate = false
	is_aura_active = true
	aura.visible = true
	
	# Terapkan slow ke semua musuh yang ada di area saat ini
	_apply_slow_to_current_enemies()
	
	# Timer untuk durasi aura
	await get_tree().create_timer(slow_duration).timeout
	
	# Nonaktifkan aura dan HENTIKAN semua slow efek
	is_aura_active = false
	aura.visible = false
	_remove_all_slows()  # Hentikan semua slow efek
	
	# Cooldown sebelum bisa aktif lagi
	await get_tree().create_timer(cooldown).timeout
	can_activate = true

func _apply_slow_to_current_enemies():
	# Bersihkan musuh yang tidak valid
	_cleanup_enemies()
	
	# Terapkan slow ke semua musuh yang saat ini ada di area
	for enemy in enemies_in_area:
		if is_instance_valid(enemy) and enemy.has_method("apply_slow"):
			enemy.apply_slow(slow_power, slow_duration)
			if not enemy in currently_slowed_enemies:
				currently_slowed_enemies.append(enemy)

func _remove_all_slows():
	# Hentikan slow efek untuk semua musuh yang sedang di-track
	for enemy in currently_slowed_enemies:
		if is_instance_valid(enemy) and enemy.has_method("remove_slow"):
			enemy.remove_slow()
	
	# Kosongkan array
	currently_slowed_enemies.clear()

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
	
	print("🧄 Garlic Tower menerima damage: ", damage, " | HP: ", current_health, "/", max_health)
	
	if current_health <= 0:
		_destroy_tower()

func _destroy_tower():
	is_destroyed = true
	repair_timer = repair_cooldown
	repair_progress = 0.0
	current_health = 0
	can_activate = false
	is_aura_active = false
	aura.visible = false
	
	# Hentikan semua slow efek
	_remove_all_slows()
	
	# Sembunyikan range visual
	if range_visual:
		range_visual.visible = false
	# Tambahkan efek visual/suara destruction di sini

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

func _repair_tower():
	is_destroyed = false
	current_health = max_health
	repair_progress = max_health
	can_activate = true
	
	# Update health bar
	if health_bar:
		health_bar.value = current_health
		health_bar.visible = true
		hide_health_timer = hide_health_delay
	
	# Sembunyikan repair label
	if repair_label:
		repair_label.visible = false
	
func _cleanup_enemies():
	# Bersihkan enemies_in_area dari musuh yang tidak valid
	var valid_enemies = []
	for enemy in enemies_in_area:
		if is_instance_valid(enemy):
			valid_enemies.append(enemy)
	enemies_in_area = valid_enemies
	
	# Juga bersihkan currently_slowed_enemies
	var valid_slowed = []
	for enemy in currently_slowed_enemies:
		if is_instance_valid(enemy):
			valid_slowed.append(enemy)
	currently_slowed_enemies = valid_slowed

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and is_instance_valid(body):
		if not body in enemies_in_area:
			enemies_in_area.append(body)
			
			# Jika aura sedang aktif, terapkan slow ke musuh baru
			if is_aura_active and body.has_method("apply_slow"):
				body.apply_slow(slow_power, slow_duration)
				if not body in currently_slowed_enemies:
					currently_slowed_enemies.append(body)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body in enemies_in_area:
			enemies_in_area.erase(body)
		
		# Jika musuh keluar area, hentikan slow-nya (jika ada)
		if body in currently_slowed_enemies:
			if is_instance_valid(body) and body.has_method("remove_slow"):
				body.remove_slow()
			currently_slowed_enemies.erase(body)
		
# ... (fungsi-fungsi lainnya tetap sama)
func _on_shape_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_mask == 1: 
		panel_upgrade.visible = true

func _on_screen_clicked(pos: Vector2) -> void:
	if panel_upgrade.visible:
		var panel_rect = panel_upgrade.get_global_rect()
		if not panel_rect.has_point(pos):
			panel_upgrade.visible = false

func _on_texture_button_pressed() -> void:
	var upgrade_cost = get_upgrade_cost()
	if GameManager.coin >= upgrade_cost:
		GameManager.coin -= upgrade_cost
		GameManager.emit_signal("update_coin", GameManager.coin)
		
		upgrade_level += 1
		apply_upgrade_stats()
		print("Garlic Tower upgraded to level ", upgrade_level)

func get_upgrade_cost() -> int:
	match upgrade_level:
		1: return upgrade_cost_level2
		2: return upgrade_cost_level3
		_: return 99999

func apply_upgrade_stats():
	match upgrade_level:
		2:
			slow_power = 0.6    # 60% slow
			slow_duration = 3.5
			cooldown = 4.5
			range_radius *= 1.2
		3:
			slow_power = 0.75   # 75% slow
			slow_duration = 4.0
			cooldown = 4.0
			range_radius *= 1.3
	
	call_deferred("setup_range_collision")
	call_deferred("update_range_visual_scale") 

var is_dragging = false

func start_drag():
	is_dragging = true
	process_mode = Node.PROCESS_MODE_DISABLED

func stop_drag():
	is_dragging = false
	process_mode = Node.PROCESS_MODE_INHERIT

func apply_nerf(nerf_type: String, power: float, duration: float):
	if is_destroyed:
		return
		
	match nerf_type:
		"cooldown":
			cooldown = original_cooldown * (1.0 + power)
		"mirror_damage":
			_apply_mirror_damage(power, duration)
	
	if nerf_type != "mirror_damage":
		active_nerfs[nerf_type] = {
			"duration": duration,
			"power": power
		}
	
	print("⚠️ Garlic Tower kena nerf: ", nerf_type, " selama ", duration, " detik")

func _apply_mirror_damage(damage_percent: float, duration: float):
	var mirror_damage = max_health * damage_percent
	take_damage(mirror_damage)
	
	can_activate = false
	await get_tree().create_timer(duration).timeout
	if not is_destroyed:
		can_activate = true

func _update_nerfs(delta: float):
	for nerf_type in active_nerfs.keys():
		active_nerfs[nerf_type].duration -= delta
		if active_nerfs[nerf_type].duration <= 0:
			_remove_nerf(nerf_type)

func _remove_nerf(nerf_type: String):
	if active_nerfs.has(nerf_type):
		match nerf_type:
			"cooldown":
				cooldown = original_cooldown
		
		active_nerfs.erase(nerf_type)
		print("✅ Nerf ", nerf_type, " telah hilang dari Garlic Tower")
		
func setup_from_data(tower_type: String, data: Dictionary):
	self.tower_type = tower_type
	self.bullet_speed = data.get("bullet_speed", 0.0)
	self.bullet_damage = data.get("bullet_damage", 0.0)
	self.cooldown = data.get("cooldown", 5.0)
	self.range_radius = data.get("range_radius", 200.0)
	self.upgrade_cost_level2 = data.get("upgrade_cost_level2", 80)
	self.upgrade_cost_level3 = data.get("upgrade_cost_level3", 160)
	
	call_deferred("setup_range_collision")
	call_deferred("update_range_visual_scale")
