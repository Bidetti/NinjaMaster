extends EnemyBase
class_name FastEnemy

enum FastEnemyState {
	IDLE,
	RUNNING,
	DASH_PREPARE,
	DASHING,
	HURT,
	DEATH
}

@export var dash_speed: float = 200.0
@export var dash_cooldown: float = 3.0
@export var dash_duration: float = 0.5
@export var dash_prepare_duration: float = 0.3
@export var dash_range_min: float = 50.0
@export var dash_range_max: float = 150.0

var dash_timer: float = 0.0
var dash_prepare_timer: float = 0.0
var dash_duration_timer: float = 0.0
var dash_direction: Vector2
var fast_enemy_state: FastEnemyState = FastEnemyState.IDLE

func _ready():
	super._ready()
	setup_fast_enemy()

func setup_fast_enemy():
	max_hp = 1
	move_speed = 80
	damage = 1
	points_value = 15
	current_hp = max_hp

func _physics_process(delta):
	if is_dead:
		return
	
	update_timers(delta)
	update_fast_enemy_state_machine(delta)
	execute_fast_enemy_movement(delta)

func update_timers(delta):
	super.update_timers(delta)
	
	if dash_timer > 0:
		dash_timer -= delta
	
	if dash_prepare_timer > 0:
		dash_prepare_timer -= delta
		if dash_prepare_timer <= 0 and fast_enemy_state == FastEnemyState.DASH_PREPARE:
			start_dash()
	
	if dash_duration_timer > 0:
		dash_duration_timer -= delta
		if dash_duration_timer <= 0 and fast_enemy_state == FastEnemyState.DASHING:
			end_dash()

func update_fast_enemy_state_machine(delta):
	if current_state == EnemyState.HURT or current_state == EnemyState.DEATH:
		fast_enemy_state = FastEnemyState.HURT if current_state == EnemyState.HURT else FastEnemyState.DEATH
		return
	
	match fast_enemy_state:
		FastEnemyState.IDLE:
			handle_fast_idle_state()
		FastEnemyState.RUNNING:
			handle_running_state()
		FastEnemyState.DASH_PREPARE:
			handle_dash_prepare_state()
		FastEnemyState.DASHING:
			handle_dashing_state()

func handle_fast_idle_state():
	if not player_ref:
		return
	
	var distance = get_distance_to_player()
	if should_start_pursuing(distance):
		change_fast_enemy_state(FastEnemyState.RUNNING)

func handle_running_state():
	if not player_ref:
		return
	
	var distance = get_distance_to_player()
	
	if can_dash() and should_dash(distance):
		prepare_dash()
	elif not should_continue_pursuing(distance):
		change_fast_enemy_state(FastEnemyState.IDLE)

func handle_dash_prepare_state():
	velocity = Vector2.ZERO
	

func handle_dashing_state():
	pass

func execute_fast_enemy_movement(delta):
	match fast_enemy_state:
		FastEnemyState.RUNNING:
			move_towards_player()
			move_and_slide()
		FastEnemyState.DASHING:
			velocity = dash_direction * dash_speed
			move_and_slide()
		FastEnemyState.DASH_PREPARE, FastEnemyState.IDLE:
			velocity = Vector2.ZERO
		_:
			super.execute_movement(delta)

func can_dash() -> bool:
	return dash_timer <= 0

func should_dash(distance: float) -> bool:
	return distance >= dash_range_min and distance <= dash_range_max

func prepare_dash():
	if not player_ref:
		return
	
	change_fast_enemy_state(FastEnemyState.DASH_PREPARE)
	dash_prepare_timer = dash_prepare_duration
	dash_direction = get_direction_to_player()
	
	modulate = Color(1.5, 1.5, 1.5)

func start_dash():
	change_fast_enemy_state(FastEnemyState.DASHING)
	dash_duration_timer = dash_duration
	dash_timer = dash_cooldown

func end_dash():
	change_fast_enemy_state(FastEnemyState.RUNNING)
	modulate = Color.WHITE

func change_fast_enemy_state(new_state: FastEnemyState):
	if fast_enemy_state == new_state:
		return
	
	fast_enemy_state = new_state
	update_fast_enemy_animation()

func update_fast_enemy_animation():
	var animation_name = get_fast_enemy_animation_name()
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)

func get_fast_enemy_animation_name() -> String:
	match fast_enemy_state:
		FastEnemyState.IDLE:
			return "Idle"
		FastEnemyState.RUNNING:
			return "Run"
		FastEnemyState.DASH_PREPARE:
			return "Dust"
		FastEnemyState.DASHING:
			return "Run"
		FastEnemyState.HURT:
			return "Hurt"
		FastEnemyState.DEATH:
			return "Death"
		_:
			return "Idle"

func update_sprite_direction(direction: Vector2):
	if fast_enemy_state == FastEnemyState.DASHING or fast_enemy_state == FastEnemyState.DASH_PREPARE:
		return
	
	if direction.x != 0:
		scale.x = abs(scale.x) if direction.x > 0 else -abs(scale.x)

func take_damage(amount: int):
	if fast_enemy_state == FastEnemyState.DASHING or fast_enemy_state == FastEnemyState.DASH_PREPARE:
		end_dash()
		dash_timer = dash_cooldown * 0.5
	
	super.take_damage(amount)

func enter_hurt_state():
	super.enter_hurt_state()
	if fast_enemy_state == FastEnemyState.DASHING or fast_enemy_state == FastEnemyState.DASH_PREPARE:
		modulate = Color.WHITE
		fast_enemy_state = FastEnemyState.HURT
