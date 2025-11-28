extends Node2D


# Tetap menggunakan @export variables untuk di-set dari CSV
@export var health := 0.0
@export var speed := 0.0
@export var coin_reward := 0.0
@export var dps_damage := 0.0

@export var can_attack_towers := false
@export var tower_damage := 0.0 
@export var tower_attack_range := 120.0  # Nilai fixed, tidak perlu dari CSV
@export var tower_attack_cooldown := 5.0  # Nilai fixed, tidak perlu dari CSV
@export var enemy_bullet_scene: PackedScene
@export var nerf_type: String = ""  # Dari CSV: "cooldown", "accuracy", dll
@export var nerf_power: float = 0.0  # Dari CSV: Besarnya efek nerf
@export var nerf_duration: float = 3.0 

var current_health := 0.0
@onready var health_bar: ProgressBar = $HealthBar
var hide_timer := 0.0
var hide_delay := 2.0

var reached_end := false
var dps_timer := 0.0
var dps_interval := 1.0
var is_attacking_base := false

var is_frozen := false
var freeze_timer := 0.0
var original_speed := 0.0

var is_slowed := false
var slow_timer := 0.0
var slow_multiplier := 1.0

# NEW: Variabel untuk menyerang tower
var tower_attack_timer := 0.0
var current_target_tower: Node = null
var towers_in_range: Array = []

@onready var status_label: Label = $StatusLabel
@onready var status_miss_label: Label = $StatusMiss  # Label untuk miss
var miss_count: int = 0
@export var is_blinded := false
var blind_timer := 0.0


func _ready():
	call_deferred("apply_csv_values")

func apply_csv_values():
	# Force set current_health berdasarkan health (yang sudah di-set dari CSV)
	current_health = health
	original_speed = speed
	
	# Setup health bar
	if health_bar:
		health_bar.max_value = health
		health_bar.value = current_health
		health_bar.visible = false
	if status_label:
		status_label.visible = false
	if status_miss_label:
		status_miss_label.visible = false
		status_miss_label.text = "MISS: 0"
		miss_count = 0
		
func _process(delta: float) -> void:
	if is_frozen:
		freeze_timer -= delta
		if freeze_timer <= 0:
			unfreeze()
	if is_slowed:
		slow_timer -= delta
		if slow_timer <= 0:
			remove_slow()
	if is_blinded:  # BARU
		blind_timer -= delta
		if blind_timer <= 0:
			remove_blind()
			
	if not reached_end and not is_frozen:
		get_parent().set_progress(get_parent().get_progress() + speed * delta)
		health_bar.rotation = 0
		
		if get_parent().get_progress_ratio() >= 0.99:
			_reach_base()
			
	if health_bar.visible:
		hide_timer -= delta
		if hide_timer <= 0:
			health_bar.visible = false
			
	if is_attacking_base:
		dps_timer -= delta
		if dps_timer <= 0:
			_attack_base()
			dps_timer = dps_interval
	
	# NEW: Logic untuk menyerang tower
	if can_attack_towers and not is_frozen:
		tower_attack_timer -= delta
		_find_tower_targets()
		if current_target_tower and tower_attack_timer <= 0:
			_attack_tower()
			tower_attack_timer = tower_attack_cooldown
	
	_update_status_display()

func apply_blind(duration: float):
	is_blinded = true
	blind_timer = duration
	current_target_tower = null  # Hentikan serangan ke tower
	towers_in_range.clear()      # Hapus target tower
	_show_status("BLIND", Color.PURPLE)

func remove_blind():
	is_blinded = false
	if not is_frozen and not is_slowed:
		_hide_status()

func add_miss():
	miss_count += 1
	
	if status_miss_label:
		status_miss_label.text = "MISS: " + str(miss_count)
		status_miss_label.visible = true
	
	print("🎯 MISS counter: ", miss_count)

# NEW: Fungsi untuk reset miss counter (opsional)
func reset_miss():
	miss_count = 0
	if status_miss_label:
		status_miss_label.visible = false
		status_miss_label.text = "MISS: 0"
		
func _find_tower_targets():
	if is_blinded:  # Jangan cari target jika blinded
		towers_in_range.clear()
		current_target_tower = null
		return
	towers_in_range = towers_in_range.filter(func(tower): return is_instance_valid(tower))
	
	# Cari tower dalam range (gunakan nilai fixed tower_attack_range)
	var all_towers = get_tree().get_nodes_in_group("tower")
	for tower in all_towers:
		if (is_instance_valid(tower) and 
			global_position.distance_to(tower.global_position) <= tower_attack_range and
			not tower.is_in_group("ignore_damage")):  # TAMBAH CHECK INI
			
			if not tower in towers_in_range:
				towers_in_range.append(tower)
	
	# Hapus tower yang sudah keluar range atau sedang di-drag
	for i in range(towers_in_range.size() - 1, -1, -1):
		var tower = towers_in_range[i]
		if (global_position.distance_to(tower.global_position) > tower_attack_range or
			tower.is_in_group("ignore_damage")):  # TAMBAH CHECK INI
			towers_in_range.remove_at(i)
	
	# Pilih target
	if towers_in_range.size() > 0:
		if not current_target_tower or not current_target_tower in towers_in_range:
			current_target_tower = towers_in_range[0]
	else:
		current_target_tower = null

func _attack_tower():
	if is_blinded:  # Jangan serang jika blinded
		return
	if not current_target_tower or not enemy_bullet_scene:
		return
	
	# Buat bullet (gunakan nilai fixed tower_attack_cooldown)
	var bullet = enemy_bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.target = current_target_tower
	bullet.nerf_type = nerf_type
	bullet.nerf_power = nerf_power
	bullet.nerf_duration = nerf_duration
	bullet.tower_damage = tower_damage 
	
	get_tree().current_scene.add_child(bullet)
	
	# Cooldown menggunakan nilai fixed
	tower_attack_timer = tower_attack_cooldown
			
func _reach_base() -> void:
	reached_end = true
	is_attacking_base = true
	dps_timer = dps_interval

func _attack_base() -> void:
	GameManager._take_damage(dps_damage)
	
func take_damage(amount: int) -> void:
	current_health -= amount
	current_health = max(current_health, 0)
	health_bar.value = current_health
	health_bar.visible = true
	hide_timer = hide_delay
	
	if current_health <= 0:
		die()

func apply_freeze(duration: float):
	if is_frozen:
		freeze_timer = duration
	else:
		is_frozen = true
		freeze_timer = duration
		speed = 0.0
		_show_status("FROZEN", Color.CYAN)

func apply_slow(slow_power: float, duration: float):
	if is_slowed:
		slow_timer = duration
		# Update slow multiplier jika slow yang baru lebih kuat
		if (1.0 - slow_power) < slow_multiplier:
			slow_multiplier = 1.0 - slow_power
			speed = original_speed * slow_multiplier
	else:
		is_slowed = true
		slow_timer = duration
		slow_multiplier = 1.0 - slow_power
		speed = original_speed * slow_multiplier
		_show_status("SLOW ", Color.YELLOW)

func unfreeze():
	is_frozen = false
	
	if is_slowed:
		speed = original_speed * slow_multiplier
	else:
		speed = original_speed
		_hide_status()

func remove_slow():
	is_slowed = false
	slow_multiplier = 1.0
	speed = original_speed
	if not is_frozen:
		_hide_status()

func _show_status(text: String, color: Color):
	if status_label:
		status_label.text = text
		status_label.modulate = color
		status_label.visible = true

# NEW: Fungsi sembunyikan status
func _hide_status():
	if status_label:
		status_label.visible = false
		
func _update_status_display():
	if not status_label:
		return
		
	if is_frozen:
		status_label.text = "FROZEN"
		status_label.modulate = Color.CYAN
		status_label.visible = true
	elif is_blinded:  # TAMBAH PRIORITAS BLIND
		status_label.text = "BLIND"
		status_label.modulate = Color.PURPLE
		status_label.visible = true
	elif is_slowed:
		var slow_percent = int((1.0 - slow_multiplier) * 100)
		status_label.text = "SLOW " + str(slow_percent) + "%"
		status_label.modulate = Color.YELLOW
		status_label.visible = true
	else:
		status_label.visible = false
		
#func _draw():
	#if Engine.is_editor_hint() or OS.is_debug_build():
		## Gambar circle merah untuk menunjukkan attack range
		#draw_circle(Vector2.ZERO, tower_attack_range, Color(1, 0, 0, 0.1))
	
func die() -> void:
	GameManager._add_coin(coin_reward)
	queue_free()
