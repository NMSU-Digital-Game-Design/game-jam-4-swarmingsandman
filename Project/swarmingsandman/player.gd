extends CharacterBody2D

var SPEED := 250.0

# ---------- WEAPONS ----------
enum WeaponType { PISTOL, SHOTGUN, RIFLE }

var weapon_type: WeaponType = WeaponType.PISTOL

var can_play: bool = false


var base_pistol_cooldown := 0.50
var time_since_shot := 0.0

# shotgun settings
var shotgun_pellets: int = 5
var shotgun_spread_deg: float = 30.0
var shotgun_cooldown: float = 0.6

# rifle settings
var rifle_cooldown: float = 0.15   # will get faster when upgraded

# per-weapon kill tracking
var pistol_kills: int = 0
var shotgun_kills: int = 0
var rifle_kills: int = 0

var pistol_level: int = 1
var shotgun_level: int = 1
var rifle_level: int = 1

# unlock flags / level
var shotgun_unlocked := false
var rifle_unlocked := false
var weapon_level: int = 1

@export var bullet_scene: PackedScene
@onready var muzzle: Marker2D = $Muzzle

# ---------- HEALTH ----------
@export var max_health: int = 10
var health: int
var damage_cooldown := 0.7   # seconds of invulnerability after a hit
var damage_timer := 0.0

@onready var sprite: Sprite2D = $Sprite2D

@export var pistol_texture: Texture2D
@export var shotgun_texture: Texture2D
@export var rifle_texture: Texture2D

func _ready() -> void:
	# Start at full health and tell Main to update the UI
	health = max_health
	var main = get_tree().current_scene
	if main.has_method("update_health"):
		main.call_deferred("update_health", health, max_health)

	# --- Set starting weapon ---
	weapon_type = WeaponType.PISTOL
	shotgun_unlocked = false
	rifle_unlocked = false
	weapon_level = 1
	
	# Start in menu → can't play yet
	can_play = false

	# Apply starting pistol sprite
	if sprite and pistol_texture:
		sprite.texture = pistol_texture
		
func set_can_play(value: bool) -> void:
	can_play = value

# ---------- MAIN LOOP ----------
func _physics_process(delta: float) -> void:
	if not can_play:
		return 
		
	_handle_weapon_switching()  
	
	# tick down damage cooldown
	if damage_timer > 0.0:
		damage_timer -= delta

	_handle_movement(delta)
	_handle_shooting(delta)

# ---------- MOVEMENT (WASD) ----------
func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * SPEED
	move_and_slide()

	# Aim the player toward the mouse
	var mouse_pos = get_global_mouse_position()
	var dir_to_mouse = (mouse_pos - global_position).angle()
	rotation = dir_to_mouse

# ---------- SHOOTING ----------
func _handle_shooting(delta: float) -> void:
	time_since_shot += delta

	# choose cooldown based on weapon type
	var current_cooldown := base_pistol_cooldown
	match weapon_type:
		WeaponType.PISTOL:
			current_cooldown = base_pistol_cooldown
		WeaponType.SHOTGUN:
			current_cooldown = shotgun_cooldown
		WeaponType.RIFLE:
			current_cooldown = rifle_cooldown

	if Input.is_action_pressed("shoot") and time_since_shot >= current_cooldown:
		time_since_shot = 0.0

		match weapon_type:
			WeaponType.PISTOL:
				_shoot_pistol()
			WeaponType.SHOTGUN:
				_shoot_shotgun()
			WeaponType.RIFLE:
				_shoot_rifle()

func _shoot_pistol() -> void:
	var dir = (get_global_mouse_position() - muzzle.global_position).normalized()
	_spawn_bullet(muzzle.global_position, dir)

func _shoot_shotgun() -> void:
	var mouse_pos = get_global_mouse_position()
	var base_dir: Vector2 = (mouse_pos - muzzle.global_position).normalized()
	var base_angle: float = base_dir.angle()
	var half_spread: float = deg_to_rad(shotgun_spread_deg) / 2.0

	if shotgun_pellets <= 1:
		_spawn_bullet(muzzle.global_position, base_dir)
		return

	for i in range(shotgun_pellets):
		var t: float = float(i) / float(shotgun_pellets - 1)  # 0..1
		var angle: float = base_angle - half_spread + t * 2.0 * half_spread
		var dir: Vector2 = Vector2.RIGHT.rotated(angle)
		_spawn_bullet(muzzle.global_position, dir)
		
func _shoot_rifle() -> void:
	var dir = (get_global_mouse_position() - muzzle.global_position).normalized()
	_spawn_bullet(muzzle.global_position, dir)
	
func _handle_weapon_switching() -> void:
	# Only allow switching AFTER all weapons are unlocked
	if not (shotgun_unlocked and rifle_unlocked):
		return

	if Input.is_action_just_pressed("switch_pistol"):
		weapon_type = WeaponType.PISTOL
		if sprite and pistol_texture:
			sprite.texture = pistol_texture

	if Input.is_action_just_pressed("switch_shotgun") and shotgun_unlocked:
		weapon_type = WeaponType.SHOTGUN
		if sprite and shotgun_texture:
			sprite.texture = shotgun_texture

	if Input.is_action_just_pressed("switch_rifle") and rifle_unlocked:
		weapon_type = WeaponType.RIFLE
		if sprite and rifle_texture:
			sprite.texture = rifle_texture

func get_weapon_kill_stats() -> Dictionary:
	return {
		"pistol": pistol_kills,
		"shotgun": shotgun_kills,
		"rifle": rifle_kills
	}
	
func _all_weapons_unlocked() -> bool:
	return shotgun_unlocked and rifle_unlocked
	
func _weapon_kills_needed(level: int) -> int:
	# 1 → 30, 2 → 60, 3 → 90, ...
	return 30 * level

func _spawn_bullet(pos: Vector2, dir: Vector2) -> void:
	if bullet_scene == null:
		return

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	bullet.global_position = pos
	if bullet.has_method("set_direction"):
		bullet.set_direction(dir.normalized())

# ---------- KILL-BASED UPGRADES ----------
func on_kill_count_changed(kills: int) -> void:
	var main = get_tree().current_scene

	# ---------- UNLOCKS (same as before) ----------
	# Rifle unlock at 60 total kills
	if kills >= 60 and not rifle_unlocked:
		rifle_unlocked = true
		weapon_type = WeaponType.RIFLE
		rifle_cooldown = 0.08

		if sprite and rifle_texture:
			sprite.texture = rifle_texture

		if main and main.has_method("show_upgrade_message"):
			main.show_upgrade_message("Rifle unlocked!", 3.0)

	# Shotgun unlock at 20 total kills
	elif kills >= 20 and not shotgun_unlocked:
		shotgun_unlocked = true
		weapon_type = WeaponType.SHOTGUN

		if sprite and shotgun_texture:
			sprite.texture = shotgun_texture

		if main and main.has_method("show_upgrade_message"):
			main.show_upgrade_message("Shotgun unlocked!", 3.0)

	# ---------- WEAPON-SPECIFIC KILL PROGRESS ----------
	_register_weapon_kill()
	
func _register_weapon_kill() -> void:
	# Don’t start weapon upgrades until all weapons are unlocked
	if not _all_weapons_unlocked():
		_update_weapon_stats_ui()
		return

	match weapon_type:
		WeaponType.PISTOL:
			pistol_kills += 1
			_check_pistol_upgrade()
		WeaponType.SHOTGUN:
			shotgun_kills += 1
			_check_shotgun_upgrade()
		WeaponType.RIFLE:
			rifle_kills += 1
			_check_rifle_upgrade()

	_update_weapon_stats_ui()
	
func _check_pistol_upgrade() -> void:
	if pistol_kills >= _weapon_kills_needed(pistol_level):
		pistol_kills = 0
		pistol_level += 1

		# Faster pistol fire, but never below 0.08 sec
		base_pistol_cooldown = max(base_pistol_cooldown * 0.9, 0.08)

		_show_weapon_upgrade_popup("Pistol", pistol_level)

func _check_shotgun_upgrade() -> void:
	if shotgun_kills >= _weapon_kills_needed(shotgun_level):
		shotgun_kills = 0
		shotgun_level += 1

		# More pellets, slight tighter spread
		shotgun_pellets = min(shotgun_pellets + 1, 10)
		shotgun_spread_deg = max(shotgun_spread_deg - 3.0, 15.0)

		_show_weapon_upgrade_popup("Shotgun", shotgun_level)

func _check_rifle_upgrade() -> void:
	if rifle_kills >= _weapon_kills_needed(rifle_level):
		rifle_kills = 0
		rifle_level += 1

		# Faster rifle fire, never below 0.04 sec
		rifle_cooldown = max(rifle_cooldown * 0.9, 0.04)

		_show_weapon_upgrade_popup("Rifle", rifle_level)

func _update_weapon_stats_ui() -> void:
	var main = get_tree().current_scene
	if main and main.has_method("update_weapon_stats"):
		main.update_weapon_stats(
			pistol_kills, pistol_level,
			shotgun_kills, shotgun_level,
			rifle_kills, rifle_level
		)

func _show_weapon_upgrade_popup(weapon_name: String, level: int) -> void:
	var main = get_tree().current_scene
	if main and main.has_method("show_upgrade_message"):
		main.show_upgrade_message("%s upgraded! (Lv %d)" % [weapon_name, level], 3.0)


#------------- Tracks Weapon Kills --------------
func on_weapon_kill() -> void:
	# Only start weapon-specific upgrades once EVERYTHING is unlocked
	if not shotgun_unlocked or not rifle_unlocked:
		return

	match weapon_type:
		WeaponType.PISTOL:
			pistol_kills += 1
			_check_pistol_upgrades()
		WeaponType.SHOTGUN:
			shotgun_kills += 1
			_check_shotgun_upgrades()
		WeaponType.RIFLE:
			rifle_kills += 1
			_check_rifle_upgrades()


#--------------- Weapons Upgrades ---------------
func _check_pistol_upgrades() -> void:
	var main = get_tree().current_scene

	# Level 2 at 50 pistol kills → faster fire
	if pistol_kills >= 50 and pistol_level == 1:
		pistol_level = 2
		base_pistol_cooldown = 0.40
		if main and main.has_method("show_upgrade_message"):
			main.show_upgrade_message("Pistol upgraded! Faster fire.", 3.0)

	# Level 3 at 120 pistol kills → even faster fire
	if pistol_kills >= 120 and pistol_level == 2:
		pistol_level = 3
		base_pistol_cooldown = 0.30
		if main and main.has_method("show_upgrade_message"):
			main.show_upgrade_message("Pistol upgraded! Blazing fire rate.", 3.0)


func _check_shotgun_upgrades() -> void:
	var main = get_tree().current_scene

	# Level 2 at 40 shotgun kills → more pellets
	if shotgun_kills >= 40 and shotgun_level == 1:
		shotgun_level = 2
		shotgun_pellets = 7
		if main and main.has_method("show_upgrade_message"):
			main.show_upgrade_message("Shotgun upgraded! More pellets.", 3.0)

	# Level 3 at 100 shotgun kills → tighter spread & faster fire
	if shotgun_kills >= 100 and shotgun_level == 2:
		shotgun_level = 3
		shotgun_pellets = 9
		shotgun_spread_deg = 24.0
		shotgun_cooldown = 0.45
		if main and main.has_method("show_upgrade_message"):
			main.show_upgrade_message("Shotgun upgraded! Stronger blast.", 3.0)


func _check_rifle_upgrades() -> void:
	var main = get_tree().current_scene

	# Level 2 at 60 rifle kills → faster fire
	if rifle_kills >= 60 and rifle_level == 1:
		rifle_level = 2
		rifle_cooldown = 0.10
		if main and main.has_method("show_upgrade_message"):
			main.show_upgrade_message("Rifle upgraded! Faster fire.", 3.0)

	# Level 3 at 150 rifle kills → very fast fire
	if rifle_kills >= 150 and rifle_level == 2:
		rifle_level = 3
		rifle_cooldown = 0.06
		if main and main.has_method("show_upgrade_message"):
			main.show_upgrade_message("Rifle upgraded! Shredder mode.", 3.0)

func add_xp(amount: int) -> void:
	var main = get_tree().current_scene
	var xp_manager = main.get_node_or_null("XPManager")
	if xp_manager and xp_manager.has_method("add_xp"):
		xp_manager.add_xp(amount, self)

func on_level_up(level: int) -> void:
	print("Player leveled up! Level:", level)

	# +1 max HP each level
	max_health += 1

	# 🔁 FULL HEAL on level up
	health = max_health

	# Every 3 levels: small speed buff
	if level % 3 == 0:
		SPEED += 15.0

	# Update HP UI
	var main = get_tree().current_scene
	if main and main.has_method("update_health"):
		main.update_health(health, max_health)

# ---------- DAMAGE / DEATH ----------
func take_damage(amount: int) -> void:
	# small invuln window so you don't get melted instantly
	if damage_timer > 0.0:
		return

	damage_timer = damage_cooldown
	health -= amount
	print("Player took damage, health:", health)

	var main = get_tree().current_scene
	if main.has_method("update_health"):
		main.update_health(health, max_health)

	if health <= 0:
		die()

func die() -> void:
	print("Player died")
	get_tree().reload_current_scene()
