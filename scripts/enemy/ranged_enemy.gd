extends EnemyBase
class_name RangedEnemy

@export var shoot_range: float = 200.0
@export var min_distance: float = 80.0
@export var shoot_cooldown: float = 2.0
@export var projectile_scene: PackedScene

var shoot_timer: float = 0.0
var is_shooting: bool = false

@onready var projectile_spawn: Marker2D = $ProjectileSpawn

func _ready():
	super._ready()
	max_hp = 2
	move_speed = 40
	damage = 1
	points_value = 20
	current_hp = max_hp
	
	if not projectile_scene:
		projectile_scene = preload("res://scenes/enemy/EnemyProjectile.tscn")

func _physics_process(delta):
	if is_dead:
		return
	
	shoot_timer -= delta
	
	if not player_ref:
		return
	
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	
	if distance_to_player <= shoot_range and distance_to_player >= min_distance:
		if shoot_timer <= 0:
			shoot()
	elif distance_to_player < min_distance:
		move_away_from_player(delta)
	elif distance_to_player > shoot_range:
		move_towards_player(delta)
		move_and_slide()

func shoot():
	if not projectile_scene or not projectile_spawn:
		return
	
	is_shooting = true
	shoot_timer = shoot_cooldown
	
	if animated_sprite.sprite_frames.has_animation("shoot"):
		animated_sprite.play("shoot")
	
	var projectile = projectile_scene.instantiate()
	projectile.global_position = projectile_spawn.global_position
	
	var direction = (player_ref.global_position - global_position).normalized()
	projectile.direction = direction
	
	get_tree().root.add_child(projectile)
	
	if audio_player:
		audio_player.play()

func move_away_from_player(delta):
	var direction = (global_position - player_ref.global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()
	update_sprite_direction(direction)

func update_sprite_direction(direction: Vector2):
	if is_shooting:
		return
	
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			if animated_sprite.sprite_frames.has_animation("walk_right"):
				animated_sprite.play("walk_right")
		else:
			if animated_sprite.sprite_frames.has_animation("walk_left"):
				animated_sprite.play("walk_left")
	else:
		if direction.y > 0:
			if animated_sprite.sprite_frames.has_animation("walk_down"):
				animated_sprite.play("walk_down")
		else:
			if animated_sprite.sprite_frames.has_animation("walk_up"):
				animated_sprite.play("walk_up")
	
	if not animated_sprite.is_playing() and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")
