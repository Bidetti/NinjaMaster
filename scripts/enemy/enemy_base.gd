extends CharacterBody2D
class_name EnemyBase

signal enemy_died(enemy)
signal health_changed(current_hp, max_hp)

@export var max_hp: int = 3
@export var move_speed: float = 50
@export var damage: int = 1
@export var points_value: int = 10

enum EnemyState {
	IDLE,
	WALKING,
	ATTACKING,
	HURT,
	DEATH
}

var current_hp: int
var player_ref: Player
var current_state: EnemyState = EnemyState.IDLE
var is_dead: bool = false

var hurt_timer: float = 0.0
var hurt_duration: float = 0.3
var state_timer: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $HitBox
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready():
	initialize_enemy()
	setup_connections()

func initialize_enemy():
	current_hp = max_hp
	player_ref = get_tree().get_first_node_in_group("player")
	change_state(EnemyState.IDLE)

func setup_connections():
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta):
	if is_dead:
		return
	
	update_timers(delta)
	update_state_machine(delta)
	
	if current_state != EnemyState.HURT and current_state != EnemyState.DEATH:
		execute_movement(delta)

func update_timers(delta):
	if hurt_timer > 0:
		hurt_timer -= delta
		if hurt_timer <= 0 and current_state == EnemyState.HURT:
			change_state(EnemyState.IDLE)
	
	state_timer += delta

func update_state_machine(delta):
	match current_state:
		EnemyState.IDLE:
			handle_idle_state()
		EnemyState.WALKING:
			handle_walking_state()
		EnemyState.ATTACKING:
			handle_attacking_state()
		EnemyState.HURT:
			handle_hurt_state()
		EnemyState.DEATH:
			handle_death_state()

func handle_idle_state():
	if not player_ref:
		return
	
	var distance_to_player = get_distance_to_player()
	if should_start_pursuing(distance_to_player):
		change_state(EnemyState.WALKING)

func handle_walking_state():
	if not player_ref:
		return
	
	var distance_to_player = get_distance_to_player()
	
	if should_attack(distance_to_player):
		change_state(EnemyState.ATTACKING)
	elif not should_continue_pursuing(distance_to_player):
		change_state(EnemyState.IDLE)

func handle_attacking_state():
	pass

func handle_hurt_state():
	velocity = Vector2.ZERO

func handle_death_state():
	velocity = Vector2.ZERO

func execute_movement(delta):
	if current_state == EnemyState.WALKING:
		move_towards_player()
		move_and_slide()

func move_towards_player():
	if not player_ref:
		return
	
	var direction = get_direction_to_player()
	velocity = direction * move_speed
	update_sprite_direction(direction)

func get_direction_to_player() -> Vector2:
	if not player_ref:
		return Vector2.ZERO
	return (player_ref.global_position - global_position).normalized()

func get_distance_to_player() -> float:
	if not player_ref:
		return INF
	return global_position.distance_to(player_ref.global_position)

func should_start_pursuing(distance: float) -> bool:
	return distance < 200.0

func should_continue_pursuing(distance: float) -> bool:
	return distance < 250.0

func should_attack(distance: float) -> bool:
	return false

func update_sprite_direction(direction: Vector2):
	pass

func change_state(new_state: EnemyState):
	if current_state == new_state:
		return
	
	exit_current_state()
	current_state = new_state
	enter_new_state()
	state_timer = 0.0

func exit_current_state():
	pass

func enter_new_state():
	update_animation()

func update_animation():
	var animation_name = get_animation_name()
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)

func get_animation_name() -> String:
	match current_state:
		EnemyState.IDLE:
			return "Idle"
		EnemyState.WALKING:
			return "Walk"
		EnemyState.ATTACKING:
			return "Attack1"
		EnemyState.HURT:
			return "Hurt"
		EnemyState.DEATH:
			return "Death"
		_:
			return "Idle"

func take_damage(amount: int):
	if is_dead or current_state == EnemyState.HURT:
		return
	
	current_hp -= amount
	health_changed.emit(current_hp, max_hp)
	
	if current_hp <= 0:
		die()
	else:
		enter_hurt_state()

func enter_hurt_state():
	change_state(EnemyState.HURT)
	hurt_timer = hurt_duration
	
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func die():
	if is_dead:
		return
	
	is_dead = true
	change_state(EnemyState.DEATH)
	collision_shape.set_deferred("disabled", true)
	
	if animated_sprite.sprite_frames.has_animation("Death"):
		animated_sprite.play("Death")
		await animated_sprite.animation_finished
	
	enemy_died.emit(self)
	queue_free()

func _on_hitbox_body_entered(body):
	if body is Player and not is_dead and current_state != EnemyState.HURT:
		pass
