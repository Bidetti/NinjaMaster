extends CharacterBody2D
class_name Player

@export var move_speed: float = 100
@export var sprint_speed: float = 150

@export var invulnerability_time: float = 1.0
@export var bullet: PackedScene

var attack_animation_timer: float = 0.0
var attack_animation_duration: float = 0.3
var invulnerable_timer: float = 0.0

enum Direction { RIGHT, LEFT }
enum VerticalAim { UP, DOWN }
enum ActionState { 
	IDLE, ATTACK, RELOADING, RUN, WALK, 
	RUN_SHOOTING, WALK_SHOOTING, WALK_RELOADING, 
	RUN_RELOADING, DEATH 
}

var current_direction: int = Direction.RIGHT
var current_vertical_aim: int = VerticalAim.DOWN
var current_action: int = ActionState.IDLE

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var death_shadow: AnimatedSprite2D = $DeathShadow
@onready var gun = $Gun
@onready var audio_player = $AudioStreamPlayer2D
@onready var hitbox: Area2D = $HitBox

func _ready():
	initialize_player()
	setup_connections()
	update_hp_bar()

func initialize_player():
	gun.bullet_scene = bullet
	add_to_group("player")

func setup_connections():
	gun.ammo_changed.connect(_on_ammo_changed)
	gun.started_reloading.connect(_on_started_reloading)
	gun.finished_reloading.connect(_on_finished_reloading)
	
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)
		hitbox.area_entered.connect(_on_hitbox_area_entered)
	
	if GameScene:
		GameScene.player_hp_changed.connect(_on_player_hp_changed)

func _process(delta):
	if GameScene.player_hp <= 0:
		handle_death_state()
		return
	
	update_timers(delta)
	handle_input()
	update_state()
	update_animation()

func _physics_process(_delta):
	move_and_slide()

func update_timers(delta):
	if attack_animation_timer > 0:
		attack_animation_timer -= delta
	
	if invulnerable_timer > 0:
		invulnerable_timer -= delta
		handle_invulnerability_effect()
	else:
		modulate.a = 1.0

func handle_invulnerability_effect():
	var frame_count = Engine.get_process_frames()
	modulate.a = 0.5 if (frame_count % 10) < 5 else 1.0

func handle_input():
	handle_movement_input()
	handle_combat_input()

func handle_movement_input():
	var move_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var current_speed = sprint_speed if Input.is_action_pressed("sprint") else move_speed
	velocity = move_vector * current_speed

func handle_combat_input():
	update_aim_direction()
	
	if Input.is_action_pressed("shoot"):
		attempt_shoot()
	
	if Input.is_action_just_pressed("reload"):
		gun.reload()

func update_aim_direction():
	var mouse_pos = get_global_mouse_position()
	current_direction = Direction.RIGHT if mouse_pos.x > global_position.x else Direction.LEFT
	
	var angle = global_position.angle_to_point(mouse_pos)
	current_vertical_aim = VerticalAim.UP if angle < 0 else VerticalAim.DOWN

func attempt_shoot():
	var mouse_pos = get_global_mouse_position()
	var shoot_direction = (mouse_pos - global_position).normalized()
	var shot_fired = gun.shoot(shoot_direction)
	
	if shot_fired:
		attack_animation_timer = attack_animation_duration

func update_state():
	if current_action == ActionState.DEATH:
		return
	
	var movement_state = get_movement_state()
	var combat_state = get_combat_state()
	
	if gun.is_reloading:
		current_action = combine_states_with_reloading(movement_state)
	elif combat_state != ActionState.IDLE:
		current_action = combine_states_with_shooting(movement_state, combat_state)
	else:
		current_action = movement_state

func get_movement_state() -> ActionState:
	var is_moving = velocity.length() > 0
	var is_sprinting = velocity.length() >= sprint_speed * 0.8
	
	if not is_moving:
		return ActionState.IDLE
	elif is_sprinting:
		return ActionState.RUN
	else:
		return ActionState.WALK

func get_combat_state() -> ActionState:
	var is_shooting = Input.is_action_pressed("shoot") and gun.can_shoot and gun.ammo > 0
	
	if attack_animation_timer > 0 or is_shooting:
		return ActionState.ATTACK
	else:
		return ActionState.IDLE

func combine_states_with_reloading(movement_state: ActionState) -> ActionState:
	match movement_state:
		ActionState.RUN:
			return ActionState.RUN_RELOADING
		ActionState.WALK:
			return ActionState.WALK_RELOADING
		_:
			return ActionState.RELOADING

func combine_states_with_shooting(movement_state: ActionState, combat_state: ActionState) -> ActionState:
	if combat_state != ActionState.ATTACK:
		return movement_state
	
	match movement_state:
		ActionState.RUN:
			return ActionState.RUN_SHOOTING
		ActionState.WALK:
			return ActionState.WALK_SHOOTING
		_:
			return ActionState.ATTACK

func update_animation():
	var animation_name = build_animation_name()
	play_animation(animation_name)
	update_gun_position()

func build_animation_name() -> String:
	var animation_prefix = "GUN_"
	var direction_part = get_direction_string()
	var action_part = get_action_string()
	
	return animation_prefix + direction_part + action_part

func get_direction_string() -> String:
	var horizontal = "RIGHT_" if current_direction == Direction.RIGHT else "LEFT_"
	var vertical = "UP_" if current_vertical_aim == VerticalAim.UP else "DOWN_"
	return horizontal + vertical

func get_action_string() -> String:
	match current_action:
		ActionState.IDLE:
			return "IDLE"
		ActionState.ATTACK:
			return "ATTACK"
		ActionState.RELOADING:
			return "RELOADING"
		ActionState.RUN:
			return "RUN"
		ActionState.WALK:
			return "WALK"
		ActionState.RUN_SHOOTING:
			return "RUN_SHOOTING"
		ActionState.WALK_SHOOTING:
			return "WALK_SHOOTING"
		ActionState.WALK_RELOADING, ActionState.RUN_RELOADING:
			return "WALK_RELOADING"
		ActionState.DEATH:
			return "DEATH"
		_:
			return "IDLE"

func play_animation(animation_name: String):
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
	else:
		play_fallback_animation()

func play_fallback_animation():
	var fallback_name = "GUN_RIGHT_DOWN_IDLE"
	if animated_sprite.sprite_frames.has_animation(fallback_name):
		animated_sprite.play(fallback_name)
	else:
		print("Animation system error: No animations found!")

func update_gun_position():
	if current_direction == Direction.RIGHT:
		gun.scale.x = 1
		gun.rotation_degrees = -45 if current_vertical_aim == VerticalAim.UP else 45
	else:
		gun.scale.x = -1
		gun.rotation_degrees = -135 if current_vertical_aim == VerticalAim.UP else 135

func handle_death_state():
	current_action = ActionState.DEATH
	death_shadow.visible = true
	play_death_animation()
	update_animation()

func play_death_animation():
	var shadow_anim = build_death_animation_name()
	death_shadow.play(shadow_anim)

func build_death_animation_name() -> String:
	var prefix = "GUN_"
	var direction = "RIGHT_" if current_direction == Direction.RIGHT else "LEFT_"
	var vertical = "UP_" if current_vertical_aim == VerticalAim.UP else "DOWN_"
	return prefix + direction + vertical + "DEATH"

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is EnemyBase and invulnerable_timer <= 0:
		take_damage(body.damage)

func _on_hitbox_area_entered(area: Node2D) -> void:
	if area is EnemyProjectile and invulnerable_timer <= 0:
		take_damage(area.damage)

func take_damage(amount: int):
	if invulnerable_timer > 0:
		return
	
	GameScene.player_hp -= amount
	invulnerable_timer = invulnerability_time
	
	play_hurt_sound()
	
	if GameScene.player_hp <= 0:
		await die()

func play_hurt_sound():
	if audio_player:
		# audio_player.stream = preload("res://path_to_hurt_sound.wav")
		# audio_player.play()
		pass

func die():
	current_action = ActionState.DEATH
	await animated_sprite.animation_finished
	await death_shadow.animation_finished
	
	respawn()

func respawn():
	GameScene.player_hp = 4
	get_tree().call_deferred("reload_current_scene")

func _on_player_hp_changed(new_hp: int):
	update_hp_bar()

func update_hp_bar():
	var hp_animation = str(clamp(GameScene.player_hp, 0, 4)) + "_hp"
	if %HPBar.sprite_frames.has_animation(hp_animation):
		%HPBar.play(hp_animation)

func _on_ammo_changed(current, maximum):
	update_ammo_display(current, maximum)

func update_ammo_display(current: int, maximum: int):
	if not $CanvasLayer.has_node("AmmoCounter"):
		create_ammo_counter()
	
	$CanvasLayer/AmmoCounter.text = str(current) + "/" + str(maximum)

func create_ammo_counter():
	var ammo_label = Label.new()
	ammo_label.name = "AmmoCounter"
	ammo_label.add_theme_font_size_override("font_size", 24)
	ammo_label.position = Vector2(150, 58)
	$CanvasLayer.add_child(ammo_label)

func _on_started_reloading():
	play_reload_sound()
	
	if $CanvasLayer.has_node("AmmoCounter"):
		$CanvasLayer/AmmoCounter.modulate = Color(1.0, 0.5, 0.0)

func _on_finished_reloading():
	play_reload_complete_sound()
	
	if $CanvasLayer.has_node("AmmoCounter"):
		$CanvasLayer/AmmoCounter.modulate = Color(1.0, 1.0, 1.0)

func play_reload_sound():
	if audio_player:
		# audio_player.stream = preload("res://path_to_reload_sound.wav")
		# audio_player.play()
		pass

func play_reload_complete_sound():
	if audio_player:
		# audio_player.stream = preload("res://path_to_reload_complete_sound.wav")
		# audio_player.play()
		pass
