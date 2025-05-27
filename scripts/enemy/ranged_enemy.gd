extends EnemyBase
class_name RangedEnemy

enum RangedEnemyState {
	IDLE,
	POSITIONING,
	AIMING,
	THROWING,
	HURT,
	DEATH
}

@export var shoot_range: float = 200.0
@export var min_distance: float = 80.0
@export var shoot_cooldown: float = 2.0
@export var aim_duration: float = 0.5
@export var throw_animation_duration: float = 0.8
@export var projectile_scene: PackedScene
@export var detection_range_override: float = 250.0
@export var flee_range: float = 70.0
@export var max_flee_range: float = 150.0

var shoot_timer: float = 0.0
var aim_timer: float = 0.0
var throw_timer: float = 0.0
var ranged_enemy_state: RangedEnemyState = RangedEnemyState.IDLE
var target_position: Vector2

@onready var projectile_spawn: Marker2D = $ProjectileSpawn

func _ready():
	super._ready()
	setup_ranged_enemy()

func setup_ranged_enemy():
	max_hp = 2
	move_speed = 40
	damage = 1
	points_value = 20
	current_hp = max_hp
	detection_range = detection_range_override
	
	if not projectile_scene:
		projectile_scene = preload("res://scenes/enemy/EnemyProjectile.tscn")

func _physics_process(delta):
	if is_dead:
		return
	
	update_timers(delta)
	update_ranged_enemy_state_machine(delta)
	execute_ranged_enemy_movement(delta)

func update_timers(delta):
	super.update_timers(delta)
	
	if shoot_timer > 0:
		shoot_timer -= delta
	
	if aim_timer > 0:
		aim_timer -= delta
		if aim_timer <= 0 and ranged_enemy_state == RangedEnemyState.AIMING:
			start_throwing()
	
	if throw_timer > 0:
		throw_timer -= delta
		if throw_timer <= 0 and ranged_enemy_state == RangedEnemyState.THROWING:
			finish_throwing()

func should_start_pursuing(distance: float) -> bool:
	return distance < detection_range_override

func should_continue_pursuing(distance: float) -> bool:
	return distance < max_flee_range

func update_ranged_enemy_state_machine(delta):
	if current_state == EnemyState.HURT or current_state == EnemyState.DEATH:
		ranged_enemy_state = RangedEnemyState.HURT if current_state == EnemyState.HURT else RangedEnemyState.DEATH
		return
	
	match ranged_enemy_state:
		RangedEnemyState.IDLE:
			handle_ranged_idle_state()
		RangedEnemyState.POSITIONING:
			handle_positioning_state()
		RangedEnemyState.AIMING:
			handle_aiming_state()
		RangedEnemyState.THROWING:
			handle_throwing_state()

func handle_ranged_idle_state():
	if not player_ref:
		return
	
	var distance = get_distance_to_player()
	
	if distance <= detection_range_override:
		if distance < flee_range:
			change_ranged_enemy_state(RangedEnemyState.POSITIONING)
		elif distance <= shoot_range and can_shoot():
			start_aiming()
		elif distance > shoot_range:
			change_ranged_enemy_state(RangedEnemyState.POSITIONING)

func handle_positioning_state():
	if not player_ref:
		return
	
	var distance = get_distance_to_player()
	
	if distance < flee_range:
		return
	
	if distance >= min_distance and distance <= shoot_range:
		if can_shoot():
			start_aiming()
		else:
			change_ranged_enemy_state(RangedEnemyState.IDLE)
	elif distance > max_flee_range:
		change_ranged_enemy_state(RangedEnemyState.IDLE)

func handle_aiming_state():
	velocity = Vector2.ZERO
	
	if player_ref:
		var direction = get_direction_to_player()
		update_sprite_direction(direction)

func handle_throwing_state():
	velocity = Vector2.ZERO

func execute_ranged_enemy_movement(delta):
	match ranged_enemy_state:
		RangedEnemyState.POSITIONING:
			execute_positioning_movement()
			move_and_slide()
		RangedEnemyState.AIMING, RangedEnemyState.THROWING:
			velocity = Vector2.ZERO
		_:
			super.execute_movement(delta)

func execute_positioning_movement():
	if not player_ref:
		return
	
	var distance = get_distance_to_player()
	var direction: Vector2
	
	if distance < flee_range:
		direction = (global_position - player_ref.global_position).normalized()
	elif distance > shoot_range:
		direction = get_direction_to_player()
	else:
		velocity = Vector2.ZERO
		return
	
	velocity = direction * move_speed
	update_sprite_direction(direction)

func can_shoot() -> bool:
	return shoot_timer <= 0

func start_aiming():
	change_ranged_enemy_state(RangedEnemyState.AIMING)
	aim_timer = aim_duration
	
	if player_ref:
		target_position = player_ref.global_position

func start_throwing():
	change_ranged_enemy_state(RangedEnemyState.THROWING)
	throw_timer = throw_animation_duration
	
	await get_tree().create_timer(throw_animation_duration * 0.6).timeout
	if ranged_enemy_state == RangedEnemyState.THROWING:
		spawn_projectile()

func spawn_projectile():
	if not projectile_scene or not projectile_spawn or not player_ref:
		return
	
	var projectile = projectile_scene.instantiate()
	projectile.global_position = projectile_spawn.global_position
	
	var direction = (player_ref.global_position - global_position).normalized()
	projectile.direction = direction
	
	get_tree().root.add_child(projectile)
	
	if audio_player:
		audio_player.play()

func finish_throwing():
	shoot_timer = shoot_cooldown
	change_ranged_enemy_state(RangedEnemyState.IDLE)

func change_ranged_enemy_state(new_state: RangedEnemyState):
	if ranged_enemy_state == new_state:
		return
	
	ranged_enemy_state = new_state
	update_ranged_enemy_animation()

func update_ranged_enemy_animation():
	var animation_name = get_ranged_enemy_animation_name()
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)

func get_ranged_enemy_animation_name() -> String:
	match ranged_enemy_state:
		RangedEnemyState.IDLE:
			return "Idle"
		RangedEnemyState.POSITIONING:
			return "Walk"
		RangedEnemyState.AIMING:
			return "AIM"
		RangedEnemyState.THROWING:
			return "Throw"
		RangedEnemyState.HURT:
			return "Hurt"
		RangedEnemyState.DEATH:
			return "Death"
		_:
			return "Idle"

func update_sprite_direction(direction: Vector2):
	if ranged_enemy_state == RangedEnemyState.THROWING:
		return
	
	if direction.x != 0:
		animated_sprite.flip_h = direction.x < 0

func take_damage(amount: int):
	if ranged_enemy_state == RangedEnemyState.AIMING or ranged_enemy_state == RangedEnemyState.THROWING:
		shoot_timer = shoot_cooldown * 0.3
		change_ranged_enemy_state(RangedEnemyState.IDLE)
	
	super.take_damage(amount)

func enter_hurt_state():
	super.enter_hurt_state()
	if ranged_enemy_state == RangedEnemyState.AIMING or ranged_enemy_state == RangedEnemyState.THROWING:
		ranged_enemy_state = RangedEnemyState.HURT
