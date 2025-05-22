extends EnemyBase
class_name MeleeEnemy

@export var attack_range: float = 30.0
@export var pursuit_range: float = 80.0
@export var attack_cooldown: float = 1.0
@export var aggressive_speed_multiplier: float = 1.5

var attack_timer: float = 0.0
var is_in_aggressive_mode: bool = false
var base_move_speed: float

func _ready():
	super._ready()
	setup_melee_enemy()

func setup_melee_enemy():
	max_hp = 2
	move_speed = 60
	damage = 1
	points_value = 10
	current_hp = max_hp
	base_move_speed = move_speed

func _physics_process(delta):
	super._physics_process(delta)
	
	if not is_dead:
		update_attack_timer(delta)
		update_aggressive_mode()

func update_attack_timer(delta):
	if attack_timer > 0:
		attack_timer -= delta

func update_aggressive_mode():
	if not player_ref:
		return
	
	var distance = get_distance_to_player()
	var should_be_aggressive = distance <= pursuit_range and distance > attack_range
	
	if should_be_aggressive != is_in_aggressive_mode:
		is_in_aggressive_mode = should_be_aggressive
		move_speed = base_move_speed * (aggressive_speed_multiplier if is_in_aggressive_mode else 1.0)

func should_start_pursuing(distance: float) -> bool:
	return distance < 200.0

func should_continue_pursuing(distance: float) -> bool:
	return distance < 250.0

func should_attack(distance: float) -> bool:
	return distance <= attack_range and attack_timer <= 0

func handle_attacking_state():
	if not player_ref:
		change_state(EnemyState.IDLE)
		return
	
	velocity = Vector2.ZERO
	
	var distance = get_distance_to_player()
	if distance > attack_range:
		change_state(EnemyState.WALKING)
		return
	
	if not animated_sprite.is_playing():
		execute_attack()
		attack_timer = attack_cooldown
		change_state(EnemyState.WALKING)

func execute_attack():
	if audio_player:
		audio_player.play()

func get_animation_name() -> String:
	match current_state:
		EnemyState.IDLE:
			return "Idle"
		EnemyState.WALKING:
			if is_in_aggressive_mode:
				return "Run"
			else:
				return "Walk"
		EnemyState.ATTACKING:
			return "Attack1"
		EnemyState.HURT:
			return "Hurt"
		EnemyState.DEATH:
			return "Death"
		_:
			return "Idle"

func update_sprite_direction(direction: Vector2):
	if current_state == EnemyState.ATTACKING:
		return
	
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			scale.x = abs(scale.x)
		else:
			scale.x = -abs(scale.x)

func enter_hurt_state():
	super.enter_hurt_state()
	attack_timer = max(attack_timer, 0.5)
