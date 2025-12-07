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

@export var is_boss := false
@export var bullet_clear_radius := 0.0  # 0 = tidak punya skill
@export var skill_cooldown := 15.0
@export var skill_duration := 1000.0

var skill_timer := 0.0
var is_skill_active := false
var skill_visual_color: Color = Color(1.0, 0.0, 1.0, 0.3)  # Magenta transparan
var skill_border_color: Color = Color(1.0, 0.5, 1.0, 0.7)

var is_burning := false
var burn_timer: Timer = null
var is_stunned := false
var stun_timer: Timer = null

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
	if is_boss and bullet_clear_radius > 0:
		if skill_timer > 0:
			skill_timer -= delta
			if skill_timer <= 0 and not is_skill_active:
				_activate_skill()
		# Update skill active duration
		if is_skill_active:
			skill_duration -= delta
			if skill_duration <= 0:
				_deactivate_skill()
	if is_skill_active and is_boss and bullet_clear_radius > 0:
		_destroy_bullets_in_range()
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
	queue_redraw()

func _destroy_bullets_in_range():
	var bullets = get_tree().get_nodes_in_group("bullet")
	
	for bullet in bullets:
		if is_instance_valid(bullet):
			var distance = global_position.distance_to(bullet.global_position)
			if distance <= bullet_clear_radius:
				print("💥 Bullet dihancurkan oleh skill")
				bullet.queue_free()
				
func _draw():
	# NEW: Draw skill circle jika skill aktif
	if is_skill_active and is_boss and bullet_clear_radius > 0:
		# Draw filled circle untuk area skill
		draw_circle(Vector2.ZERO, bullet_clear_radius, skill_visual_color)
		
		# Draw border
		draw_arc(Vector2.ZERO, bullet_clear_radius, 0, TAU, 32, skill_border_color, 3.0)
		
		# Draw pulsating effect
		var pulse = abs(sin(Time.get_ticks_msec() * 0.005)) * 0.2 + 0.8
		var pulse_color = Color(skill_border_color.r, skill_border_color.g, skill_border_color.b, pulse)
		draw_arc(Vector2.ZERO, bullet_clear_radius + 5, 0, TAU, 32, pulse_color, 1.0)

func _activate_skill():
	print("🔥 BOSS menggunakan skill: BULLET CLEAR!")
	is_skill_active = true
	
	# Hapus semua bullet dalam radius
	_clear_bullets_in_area()
	
	# Tampilkan status skill
	_show_status("BULLET CLEAR!", Color.MAGENTA)
	
	# Set timer untuk deaktifasi
	skill_duration = 4.0  # Reset duration

# NEW: Fungsi untuk deaktivasi skill
func _deactivate_skill():
	print("✅ Skill BOSS berakhir")
	is_skill_active = false
	
	# Mulai cooldown skill
	skill_timer = skill_cooldown
	
	# Sembunyikan status
	if not is_frozen and not is_slowed and not is_blinded:
		_hide_status()

# NEW: Fungsi untuk menghapus bullet dalam area
func _clear_bullets_in_area():
	# Cari semua bullet dalam scene
	var bullets = get_tree().get_nodes_in_group("bullet")
	var bullets_cleared = 0
	
	for bullet in bullets:
		if is_instance_valid(bullet):
			# Cek jika bullet dalam radius skill
			var distance = global_position.distance_to(bullet.global_position)
			if distance <= bullet_clear_radius:
				# Hapus bullet
				bullet.queue_free()
				bullets_cleared += 1
	
	print("💥 BOSS menghapus " + str(bullets_cleared) + " bullet")
	
func apply_blind(duration: float):
	is_blinded = true
	blind_timer = duration
	current_target_tower = null  # Hentikan serangan ke tower
	towers_in_range.clear()      # Hapus target tower
	_show_status("BLIND", Color.PURPLE)
	if is_skill_active:
		_deactivate_skill()

func remove_blind():
	is_blinded = false
	if not is_frozen and not is_slowed:
		_hide_status()

func add_miss():
	miss_count += 1
	
	if status_miss_label:
		status_miss_label.text = "MISS: " + str(miss_count)
		status_miss_label.visible = true
		
		get_tree().create_timer(0.5).timeout.connect(_hide_miss_label)
	
	print("🎯 MISS counter: ", miss_count)

func _hide_miss_label():
	if status_miss_label:
		status_miss_label.visible = false
	miss_count = 0
	
# NEW: Fungsi untuk reset miss counter (opsional)
func reset_miss():
	miss_count = 0
	if status_miss_label:
		status_miss_label.visible = false
		status_miss_label.text = "MISS: 0"
		
func _find_tower_targets():
	if is_blinded or is_skill_active:  # Jangan cari target jika blinded
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
	if is_blinded or is_skill_active:  # Jangan serang jika blinded
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
	
	if is_boss and bullet_clear_radius > 0 and not is_skill_active and skill_timer <= 0:
		var health_percentage = (current_health / health) * 100
		if health_percentage <= 75:  # Aktifkan skill saat HP <= 75%
			skill_timer = 0.1
			
	if current_health <= 0:
		die()

func apply_freeze(duration: float):
	if is_frozen:
		freeze_timer = duration
	if is_skill_active:
			_deactivate_skill()
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
		
func apply_burn(duration: float):
	if is_burning:
		return
	
	print("🔥 Enemy terkena BURN!")
	is_burning = true
	_show_status("BURN", Color.ORANGE)
	
	# Damage over time: 5 damage per detik
	var damage_per_second = 5.0
	var tick_interval = 0.5
	var ticks = duration / tick_interval
	var damage_per_tick = damage_per_second * tick_interval
	
	var burn_timer = Timer.new()
	burn_timer.wait_time = tick_interval
	burn_timer.one_shot = false
	add_child(burn_timer)
	
	burn_timer.timeout.connect(func():
		if is_instance_valid(self):
			take_damage(int(damage_per_tick))
			print("🔥 Burn tick: ", int(damage_per_tick))
	)
	
	burn_timer.start()
	
	await get_tree().create_timer(duration).timeout
	burn_timer.stop()
	burn_timer.queue_free()
	is_burning = false
	
	if not is_frozen and not is_slowed and not is_blinded:
		_hide_status()

# Fungsi untuk efek stun
func apply_stun(duration: float):
	if is_frozen or is_blinded or is_stunned:
		return
	
	print("😵 Enemy terkena STUN!")
	is_stunned = true
	var original_speed_temp = speed
	speed = 0
	_show_status("STUN", Color.PURPLE)
	
	var stun_timer = Timer.new()
	stun_timer.wait_time = duration
	stun_timer.one_shot = true
	add_child(stun_timer)
	
	stun_timer.timeout.connect(func():
		if is_instance_valid(self):
			is_stunned = false
			if not is_frozen and not is_blinded:
				speed = original_speed_temp
				_hide_status()
	)
	
	stun_timer.start()
	
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
	elif is_skill_active:  # TAMBAH STATUS SKILL
		status_label.text = "BULLET CLEAR!"
		status_label.modulate = Color.MAGENTA
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
