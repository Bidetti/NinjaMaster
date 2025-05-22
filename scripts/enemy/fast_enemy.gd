extends EnemyBase
class_name FastEnemy

@export var dash_speed: float = 200.0
@export var dash_cooldown: float = 3.0
@export var dash_duration: float = 0.5

var dash_timer: float = 0.0
var is_dashing: bool = false
var dash_direction: Vector2

func _ready():
	super._ready()
	max_hp = 1
	move_speed = 80
	damage = 1
	points_value = 15
	current_hp = max_hp

func _physics_process(delta):
	if is_dead:
		return
	
	dash_timer -= delta
	
	if is_dashing:
		velocity = dash_direction * dash_speed
		move_and_slide()
		return
	
	if player_ref:
		var distance_to_player = global_position.distance_to(player_ref.global_position)
		
		if distance_to_player > 50 and distance_to_player < 150 and dash_timer <= 0:
			start_dash()
		else:
			move_towards_player(delta)
			move_and_slide()

func start_dash():
	if not player_ref:
		return
	
	is_dashing = true
	dash_timer = dash_cooldown
	dash_direction = (player_ref.global_position - global_position).normalized()
	
	modulate = Color(1.5, 1.5, 1.5)
	
	if animated_sprite.sprite_frames.has_animation("dash"):
		animated_sprite.play("dash")
	
	var dash_duration_timer = get_tree().create_timer(dash_duration)
	dash_duration_timer.timeout.connect(_on_dash_finished)

func _on_dash_finished():
	is_dashing = false
	modulate = Color.WHITE

func update_sprite_direction(direction: Vector2):
	if is_dashing:
		return
	
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			if animated_sprite.sprite_frames.has_animation("run_right"):
				animated_sprite.play("run_right")
		else:
			if animated_sprite.sprite_frames.has_animation("run_left"):
				animated_sprite.play("run_left")
	else:
		if direction.y > 0:
			if animated_sprite.sprite_frames.has_animation("run_down"):
				animated_sprite.play("run_down")
		else:
			if animated_sprite.sprite_frames.has_animation("run_up"):
				animated_sprite.play("run_up")
	
	if not animated_sprite.is_playing() and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")
