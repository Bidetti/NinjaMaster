extends EnemyBase
class_name MeleeEnemy

@export var attack_range: float = 30.0
@export var attack_cooldown: float = 1.0

var attack_timer: float = 0.0
var is_attacking: bool = false

func _ready():
	super._ready()
	max_hp = 2
	move_speed = 60
	damage = 1
	points_value = 10
	current_hp = max_hp

func _physics_process(delta):
	if is_dead:
		return
	
	attack_timer -= delta
	
	if player_ref:
		var distance_to_player = global_position.distance_to(player_ref.global_position)
		
		if distance_to_player <= attack_range and attack_timer <= 0:
			attack()
		else:
			move_towards_player(delta)
			move_and_slide()

func attack():
	is_attacking = true
	attack_timer = attack_cooldown
	
	if animated_sprite.sprite_frames.has_animation("attack"):
		animated_sprite.play("attack")
	
	if player_ref and global_position.distance_to(player_ref.global_position) <= attack_range:
		pass

func update_sprite_direction(direction: Vector2):
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
