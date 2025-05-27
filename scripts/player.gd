extends CharacterBody2D
class_name Player

@export var move_speed: float = 100
@export var sprint_speed: float = 150

@export var bullet: PackedScene
var attack_animation_timer: float = 0.0
var attack_animation_duration: float = 0.3
var is_dead: bool = false

var hurt_flash_timer: float = 0.0
var hurt_flash_duration: float = 0.2
var hurt_flash_interval: float = 0.05
var is_flashing: bool = false

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
	if is_dead:
		return
		
	if GameScene.player_hp <= 0:
		handle_death_state()
		return
	
	update_timers(delta)
	update_hurt_flash(delta)
	handle_input()
	update_state()
	update_animation()

func _physics_process(_delta):
	if is_dead:
		return
	move_and_slide()

func update_timers(delta):
	if attack_animation_timer > 0:
		attack_animation_timer -= delta

func update_hurt_flash(delta):
	if hurt_flash_timer > 0:
		hurt_flash_timer -= delta
		
		var flash_cycle = fmod(hurt_flash_timer, hurt_flash_interval * 2)
		var should_be_red = flash_cycle > hurt_flash_interval
		
		if should_be_red:
			animated_sprite.modulate = Color(1.5, 0.3, 0.3, 1.0)
			gun.modulate = Color(1.5, 0.3, 0.3, 1.0)
		else:
			animated_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
			gun.modulate = Color(1.0, 1.0, 1.0, 1.0)
		
		is_flashing = true
	else:
		if is_flashing:
			# Finalizar o efeito e restaurar a cor normal
			animated_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
			gun.modulate = Color(1.0, 1.0, 1.0, 1.0)
			is_flashing = false


func start_hurt_flash():
	hurt_flash_timer = hurt_flash_duration
	is_flashing = true

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
	is_dead = true
	current_action = ActionState.DEATH
	death_shadow.visible = true
	play_death_animation()
	update_animation()
	show_restart_button()

func play_death_animation():
	var shadow_anim = build_death_animation_name()
	death_shadow.play(shadow_anim)

func build_death_animation_name() -> String:
	var prefix = "GUN_"
	var direction = "RIGHT_" if current_direction == Direction.RIGHT else "LEFT_"
	var vertical = "UP_" if current_vertical_aim == VerticalAim.UP else "DOWN_"
	return prefix + direction + vertical + "DEATH"

func show_restart_button():
	var restart_button = Button.new()
	restart_button.text = "REINICIAR"
	restart_button.name = "RestartButton"
	
	restart_button.add_theme_font_size_override("font_size", 32)
	restart_button.add_theme_color_override("font_color", Color.WHITE)
	restart_button.add_theme_color_override("font_color_hover", Color.YELLOW)
	restart_button.add_theme_color_override("font_color_pressed", Color.RED)
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style_normal.border_width_left = 3
	style_normal.border_width_right = 3
	style_normal.border_width_top = 3
	style_normal.border_width_bottom = 3
	style_normal.border_color = Color.WHITE
	style_normal.corner_radius_top_left = 10
	style_normal.corner_radius_top_right = 10
	style_normal.corner_radius_bottom_left = 10
	style_normal.corner_radius_bottom_right = 10
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.3, 0.3, 0.3, 0.9)
	style_hover.border_width_left = 3
	style_hover.border_width_right = 3
	style_hover.border_width_top = 3
	style_hover.border_width_bottom = 3
	style_hover.border_color = Color.YELLOW
	style_hover.corner_radius_top_left = 10
	style_hover.corner_radius_top_right = 10
	style_hover.corner_radius_bottom_left = 10
	style_hover.corner_radius_bottom_right = 10
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style_pressed.border_width_left = 3
	style_pressed.border_width_right = 3
	style_pressed.border_width_top = 3
	style_pressed.border_width_bottom = 3
	style_pressed.border_color = Color.RED
	style_pressed.corner_radius_top_left = 10
	style_pressed.corner_radius_top_right = 10
	style_pressed.corner_radius_bottom_left = 10
	style_pressed.corner_radius_bottom_right = 10
	
	restart_button.add_theme_stylebox_override("normal", style_normal)
	restart_button.add_theme_stylebox_override("hover", style_hover)
	restart_button.add_theme_stylebox_override("pressed", style_pressed)
	
	restart_button.size = Vector2(200, 60)
	restart_button.position = Vector2(
		(get_viewport().size.x - restart_button.size.x) / 2,
		(get_viewport().size.y - restart_button.size.y) / 2
	)
	
	restart_button.pressed.connect(_on_restart_button_pressed)
	
	$CanvasLayer.add_child(restart_button)

func _on_restart_button_pressed():
	restart_game()

func restart_game():
	GameScene.player_hp = 4
	get_tree().call_deferred("reload_current_scene")

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is EnemyBase and not is_dead:
		take_damage(body.damage)

func _on_hitbox_area_entered(area: Node2D) -> void:
	if area is EnemyProjectile and not is_dead:
		take_damage(area.damage)

func take_damage(amount: int):
	if is_dead:
		return
	
	GameScene.player_hp -= amount
	start_hurt_flash()
	
	play_hurt_sound()
	
	if GameScene.player_hp <= 0:
		handle_death_state()

func play_hurt_sound():
	if audio_player:
		# audio_player.stream = preload("res://path_to_hurt_sound.wav")
		# audio_player.play()
		pass

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
