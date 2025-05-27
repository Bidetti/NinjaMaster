extends EnemyBase
class_name DashEnemy

enum DashEnemyState {
	IDLE,
	WALKING,
	RUNNING,
	ATTACKING,
	RETREATING,
	DASH_PREPARE,
	DASH_ATTACK,
	HURT,
	DEATH
}

@export var retreat_distance: float = 120.0
@export var dash_speed: float = 250.0
@export var dash_range: float = 150.0
@export var dash_cooldown: float = 4.0
@export var retreat_speed: float = 120.0
@export var dash_prepare_duration: float = 1.0
@export var dash_duration: float = 0.8
@export var min_dash_distance: float = 60.0
@export var max_dash_distance: float = 200.0
@export var attack_range: float = 40.0
@export var attack_duration: float = 0.5

var dash_timer: float = 0.0
var dash_prepare_timer: float = 0.0
var dash_duration_timer: float = 0.0
var retreat_timer: float = 0.0
var retreat_duration: float = 1.5
var attack_timer: float = 0.0

var dash_direction: Vector2
var retreat_target: Vector2
var dash_enemy_state: DashEnemyState = DashEnemyState.IDLE
var base_move_speed: float

@onready var dust_particles: GPUParticles2D

func _ready():
	super._ready()
	setup_dash_enemy()
	create_dust_particles()

func setup_dash_enemy():
	max_hp = 3
	move_speed = 85
	damage = 2
	points_value = 30
	detection_range = 300.0
	current_hp = max_hp
	base_move_speed = move_speed

func create_dust_particles():
	dust_particles = GPUParticles2D.new()
	dust_particles.emitting = false
	dust_particles.amount = 50
	dust_particles.lifetime = 1.0
	add_child(dust_particles)

func _physics_process(delta):
	if is_dead:
		return
	
	update_timers(delta)
	update_dash_enemy_state_machine(delta)
	execute_dash_enemy_movement(delta)

func update_timers(delta):
	super.update_timers(delta)
	
	if dash_timer > 0:
		dash_timer -= delta
	
	if dash_prepare_timer > 0:
		dash_prepare_timer -= delta
		if dash_prepare_timer <= 0 and dash_enemy_state == DashEnemyState.DASH_PREPARE:
			start_dash_attack()
	
	if dash_duration_timer > 0:
		dash_duration_timer -= delta
		if dash_duration_timer <= 0 and dash_enemy_state == DashEnemyState.DASH_ATTACK:
			end_dash_attack()
	
	if retreat_timer > 0:
		retreat_timer -= delta
		if retreat_timer <= 0 and dash_enemy_state == DashEnemyState.RETREATING:
			finish_retreat()
	
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0 and dash_enemy_state == DashEnemyState.ATTACKING:
			finish_basic_attack()


func update_dash_enemy_state_machine(delta):
	if current_state == EnemyState.HURT or current_state == EnemyState.DEATH:
		dash_enemy_state = DashEnemyState.HURT if current_state == EnemyState.HURT else DashEnemyState.DEATH
		return
	
	match dash_enemy_state:
		DashEnemyState.IDLE:
			handle_dash_idle_state()
		DashEnemyState.WALKING:
			handle_dash_walking_state()
		DashEnemyState.RUNNING:
			handle_dash_running_state()
		DashEnemyState.ATTACKING:
			handle_attacking_state()
		DashEnemyState.RETREATING:
			handle_retreating_state()
		DashEnemyState.DASH_PREPARE:
			handle_dash_prepare_state()
		DashEnemyState.DASH_ATTACK:
			handle_dash_attack_state()

func handle_dash_idle_state():
	if not player_ref:
		return
	
	var distance = get_distance_to_player()
	if should_start_pursuing(distance):
		change_dash_enemy_state(DashEnemyState.WALKING)

func handle_dash_walking_state():
	if not player_ref:
		return
	
	var distance = get_distance_to_player()
	
	if distance <= attack_range:
		start_basic_attack()
	elif should_run_towards_player(distance):
		change_dash_enemy_state(DashEnemyState.RUNNING)
	elif should_prepare_super_dash(distance):
		start_retreat_for_dash()
	elif not should_continue_pursuing(distance):
		change_dash_enemy_state(DashEnemyState.IDLE)

func handle_dash_running_state():
	if not player_ref:
		return
	
	var distance = get_distance_to_player()
	
	if distance <= attack_range:
		start_basic_attack()
	elif should_prepare_super_dash(distance):
		start_retreat_for_dash()
	elif not should_run_towards_player(distance):
		change_dash_enemy_state(DashEnemyState.WALKING)

func handle_attacking_state():
	velocity = Vector2.ZERO

func handle_retreating_state():
	pass

func handle_dash_prepare_state():
	velocity = Vector2.ZERO
	
	if dust_particles:
		dust_particles.emitting = true

func handle_dash_attack_state():
	pass

func execute_dash_enemy_movement(delta):
	match dash_enemy_state:
		DashEnemyState.WALKING:
			move_towards_player_with_speed(base_move_speed)
			move_and_slide()
		DashEnemyState.RUNNING:
			move_towards_player_with_speed(base_move_speed * 1.3)
			move_and_slide()
		DashEnemyState.ATTACKING:
			velocity = Vector2.ZERO
		DashEnemyState.RETREATING:
			execute_retreat_movement()
			move_and_slide()
		DashEnemyState.DASH_ATTACK:
			execute_dash_movement()
			move_and_slide()
		DashEnemyState.DASH_PREPARE:
			velocity = Vector2.ZERO
		_:
			super.execute_movement(delta)

func move_towards_player_with_speed(speed: float):
	if not player_ref:
		return
	
	var direction = get_direction_to_player()
	velocity = direction * speed
	update_sprite_direction(direction)

func execute_retreat_movement():
	if retreat_target == Vector2.ZERO:
		return
	
	var direction = (retreat_target - global_position).normalized()
	velocity = direction * retreat_speed
	update_sprite_direction(direction)

func start_basic_attack():
	change_dash_enemy_state(DashEnemyState.ATTACKING)
	attack_timer = attack_duration
	
	if player_ref and get_distance_to_player() <= attack_range:
		# Assumindo que o player tem uma função take_damage
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage)

func finish_basic_attack():
	var distance = get_distance_to_player()
	
	if should_prepare_super_dash(distance):
		start_retreat_for_dash()
	elif should_run_towards_player(distance):
		change_dash_enemy_state(DashEnemyState.RUNNING)
	else:
		change_dash_enemy_state(DashEnemyState.WALKING)

func execute_dash_movement():
	velocity = dash_direction * dash_speed
	
	if player_ref and global_position.distance_to(player_ref.global_position) <= 50.0:
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage * 2) # Dash causa mais dano


func should_run_towards_player(distance: float) -> bool:
	return distance < 100.0 and distance > 40.0

func should_prepare_super_dash(distance: float) -> bool:
	return (can_dash() and 
			distance >= min_dash_distance and 
			distance <= max_dash_distance and
			dash_enemy_state != DashEnemyState.RETREATING)

func can_dash() -> bool:
	return dash_timer <= 0

func start_retreat_for_dash():
	if not player_ref:
		return
	
	change_dash_enemy_state(DashEnemyState.RETREATING)
	retreat_timer = retreat_duration
	
	var direction_from_player = (global_position - player_ref.global_position).normalized()
	retreat_target = global_position + (direction_from_player * retreat_distance)
	
	modulate = Color(1.2, 1.2, 0.8)

func finish_retreat():
	if not player_ref:
		change_dash_enemy_state(DashEnemyState.IDLE)
		return
	
	prepare_dash_attack()

func prepare_dash_attack():
	change_dash_enemy_state(DashEnemyState.DASH_PREPARE)
	dash_prepare_timer = dash_prepare_duration
	
	if player_ref:
		dash_direction = (player_ref.global_position - global_position).normalized()
	
	modulate = Color(1.5, 0.8, 0.8)
	
	if dust_particles:
		dust_particles.emitting = true

func start_dash_attack():
	change_dash_enemy_state(DashEnemyState.DASH_ATTACK)
	dash_duration_timer = dash_duration
	dash_timer = dash_cooldown
	
	modulate = Color(1.8, 1.0, 1.0)
	
	if dust_particles:
		dust_particles.emitting = false

func end_dash_attack():
	change_dash_enemy_state(DashEnemyState.RUNNING)
	modulate = Color.WHITE
	retreat_target = Vector2.ZERO
	
	if dust_particles:
		dust_particles.emitting = false

func change_dash_enemy_state(new_state: DashEnemyState):
	if dash_enemy_state == new_state:
		return
	
	exit_dash_state()
	dash_enemy_state = new_state
	enter_dash_state()
	update_dash_enemy_animation()

func exit_dash_state():
	if dust_particles:
		dust_particles.emitting = false

func enter_dash_state():
	pass

func update_dash_enemy_animation():
	var animation_name = get_dash_enemy_animation_name()
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)

func get_dash_enemy_animation_name() -> String:
	match dash_enemy_state:
		DashEnemyState.IDLE:
			return "Idle"
		DashEnemyState.WALKING:
			return "Walk"
		DashEnemyState.RUNNING:
			return "Run"
		DashEnemyState.ATTACKING:
			return "Attack"
		DashEnemyState.RETREATING:
			return "Jump"
		DashEnemyState.DASH_PREPARE:
			return "Dust"
		DashEnemyState.DASH_ATTACK:
			return "Attack"
		DashEnemyState.HURT:
			return "Hurt"
		DashEnemyState.DEATH:
			return "Death"
		_:
			return "Idle"

func update_sprite_direction(direction: Vector2):
	if dash_enemy_state == DashEnemyState.DASH_ATTACK or dash_enemy_state == DashEnemyState.DASH_PREPARE:
		return
	
	if direction.x != 0:
		animated_sprite.flip_h = direction.x < 0

func take_damage(amount: int):
	if dash_enemy_state == DashEnemyState.DASH_PREPARE or dash_enemy_state == DashEnemyState.DASH_ATTACK:
		end_dash_attack()
		dash_timer = dash_cooldown * 0.7
	
	super.take_damage(amount)

func enter_hurt_state():
	super.enter_hurt_state()
	
	if dash_enemy_state == DashEnemyState.DASH_PREPARE or dash_enemy_state == DashEnemyState.DASH_ATTACK:
		modulate = Color.WHITE
		dash_enemy_state = DashEnemyState.HURT
		if dust_particles:
			dust_particles.emitting = false

func die():
	if dust_particles:
		dust_particles.emitting = false
	modulate = Color.WHITE
	
	super.die()

func get_animation_name() -> String:
	return get_dash_enemy_animation_name()
