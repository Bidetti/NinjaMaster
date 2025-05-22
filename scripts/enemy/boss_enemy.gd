extends EnemyBase
class_name BossEnemy

signal boss_defeated

@export var phase_2_hp_threshold: int = 15
@export var charge_speed: float = 150.0
@export var charge_cooldown: float = 4.0
@export var projectile_scene: PackedScene
@export var minion_scene: PackedScene

var current_phase: int = 1
var charge_timer: float = 0.0
var attack_pattern_timer: float = 0.0
var is_charging: bool = false
var charge_direction: Vector2

@onready var projectile_spawn_1: Marker2D = $ProjectileSpawn1
@onready var projectile_spawn_2: Marker2D = $ProjectileSpawn2
@onready var projectile_spawn_3: Marker2D = $ProjectileSpawn3

func _ready():
	super._ready()
	max_hp = 30
	move_speed = 30
	damage = 2
	points_value = 100
	current_hp = max_hp
	
	if not projectile_scene:
		projectile_scene = preload("res://scenes/enemy/EnemyProjectile.tscn")
	if not minion_scene:
		minion_scene = preload("res://scenes/enemy/MeleeEnemy.tscn")

func _physics_process(delta):
	if is_dead:
		return
	
	charge_timer -= delta
	attack_pattern_timer -= delta
	
	if current_phase == 1 and current_hp <= phase_2_hp_threshold:
		enter_phase_2()
	
	if is_charging:
		velocity = charge_direction * charge_speed
		move_and_slide()
		return
	
	if current_phase == 1:
		phase_1_behavior(delta)
	else:
		phase_2_behavior(delta)

func phase_1_behavior(delta):
	if not player_ref:
		return
	
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	
	if attack_pattern_timer <= 0:
		attack_pattern_timer = 3.0
		shoot_triple_shot()
	
	if distance_to_player > 100 and charge_timer <= 0:
		start_charge()
	else:
		move_towards_player(delta)
		move_and_slide()

func phase_2_behavior(delta):
	if not player_ref:
		return
	
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	
	if attack_pattern_timer <= 0:
		attack_pattern_timer = 2.0
		
		var attack_type = randi() % 3
		match attack_type:
			0:
				shoot_triple_shot()
			1:
				summon_minions()
			2:
				shoot_spread_attack()
	
	if distance_to_player > 80 and charge_timer <= 0:
		start_charge()
	else:
		move_towards_player(delta)
		move_and_slide()

func shoot_triple_shot():
	if not projectile_scene or not player_ref:
		return
	
	if animated_sprite.sprite_frames.has_animation("attack"):
		animated_sprite.play("attack")
	
	var direction = (player_ref.global_position - global_position).normalized()
	
	create_projectile(projectile_spawn_1.global_position, direction)
	
	var angle_offset = deg_to_rad(30)
	create_projectile(projectile_spawn_2.global_position, direction.rotated(angle_offset))
	create_projectile(projectile_spawn_3.global_position, direction.rotated(-angle_offset))

func shoot_spread_attack():
	if not projectile_scene:
		return
	
	if animated_sprite.sprite_frames.has_animation("special_attack"):
		animated_sprite.play("special_attack")
	
	# Ataque em leque com 5 projéteis
	var base_direction = (player_ref.global_position - global_position).normalized()
	
	for i in range(-2, 3):
		var angle = deg_to_rad(i * 20)
		var direction = base_direction.rotated(angle)
		create_projectile(global_position, direction)

func summon_minions():
	if not minion_scene:
		return
	
	if animated_sprite.sprite_frames.has_animation("summon"):
		animated_sprite.play("summon")
	
	for i in range(2):
		var minion = minion_scene.instantiate()
		var spawn_angle = randf() * TAU
		var spawn_distance = 60.0
		var spawn_pos = global_position + Vector2.from_angle(spawn_angle) * spawn_distance
		
		minion.global_position = spawn_pos
		get_tree().root.add_child(minion)

func create_projectile(spawn_pos: Vector2, direction: Vector2):
	var projectile = projectile_scene.instantiate()
	projectile.global_position = spawn_pos
	projectile.direction = direction
	get_tree().root.add_child(projectile)

func start_charge():
	if not player_ref:
		return
	
	is_charging = true
	charge_timer = charge_cooldown
	charge_direction = (player_ref.global_position - global_position).normalized()
	
	modulate = Color(2.0, 1.0, 1.0)
	
	if animated_sprite.sprite_frames.has_animation("charge"):
		animated_sprite.play("charge")
	
	var charge_duration = get_tree().create_timer(1.0)
	charge_duration.timeout.connect(_on_charge_finished)

func _on_charge_finished():
	is_charging = false
	modulate = Color.WHITE

func enter_phase_2():
	current_phase = 2
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.5)
	tween.tween_property(self, "modulate", Color.WHITE, 0.5)
	
	move_speed = 50
	
	if animated_sprite.sprite_frames.has_animation("phase_change"):
		animated_sprite.play("phase_change")

func die():
	boss_defeated.emit()
	super.die()

func update_sprite_direction(direction: Vector2):
	if is_charging or is_shooting:
		return
	
	if player_ref:
		var to_player = player_ref.global_position - global_position
		if abs(to_player.x) > abs(to_player.y):
			if to_player.x > 0:
				if animated_sprite.sprite_frames.has_animation("idle_right"):
					animated_sprite.play("idle_right")
			else:
				if animated_sprite.sprite_frames.has_animation("idle_left"):
					animated_sprite.play("idle_left")
		else:
			if to_player.y > 0:
				if animated_sprite.sprite_frames.has_animation("idle_down"):
					animated_sprite.play("idle_down")
			else:
				if animated_sprite.sprite_frames.has_animation("idle_up"):
					animated_sprite.play("idle_up")
	
	if not animated_sprite.is_playing() and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")
