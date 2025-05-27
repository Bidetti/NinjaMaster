extends Node2D
class_name WaveManager

signal wave_started(wave_number)
signal wave_completed(wave_number)
signal all_waves_completed

@export var enemy_scenes: Array[PackedScene] = []
@export var spawn_points: Array[Vector2] = []
@export var time_between_waves: float = 3.0
@export var time_between_spawns: float = 0.3
var current_wave: int = 0
var max_waves: int = 3
var enemies_alive: int = 0
var wave_in_progress: bool = false
var player_ref: Player
var waves_started: bool = false

@onready var spawn_timer: Timer = $SpawnTimer
@onready var wave_timer: Timer = $WaveTimer

func _ready():
	player_ref = get_tree().get_first_node_in_group("player")
	
	spawn_timer.wait_time = time_between_spawns
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	wave_timer.wait_time = time_between_waves
	
	if spawn_points.is_empty():
		generate_spawn_points()
	
	if enemy_scenes.is_empty():
		load_default_enemy_scenes()

func start_waves():
	if not waves_started:
		waves_started = true
		await get_tree().create_timer(2.0).timeout
		start_next_wave()

func generate_spawn_points():
	var map_center = Vector2.ZERO
	var spawn_radius = 25.0
	
	for i in range(8):
		var angle = (i * TAU) / 8.0
		var spawn_point = map_center + Vector2.from_angle(angle) * spawn_radius
		spawn_points.append(spawn_point)

func load_default_enemy_scenes():
	enemy_scenes = [
		preload("res://scenes/enemy/MeleeEnemy.tscn"),
		preload("res://scenes/enemy/FastEnemy.tscn")
	]

func generate_wave_config(wave_number: int) -> Dictionary:
	var config = {"enemies": []}
	
	var difficulty_factor = 1.0 + (wave_number - 1) * 0.25
	
	var melee_count = max(3, int(5 + wave_number * 1.5))
	var fast_count = max(0, int((wave_number - 1) * 1.2))
	var ranged_count = max(0, int((wave_number - 2) * 0.8))
	
	if wave_number % 5 == 0:
		melee_count += 4
		fast_count += 3
		ranged_count += 2
	
	if wave_number % 10 == 0:
		melee_count += 6
		fast_count += 4
		ranged_count += 3
	
	melee_count = min(melee_count, 25)  # Era 15
	fast_count = min(fast_count, 20)   # Era 12
	ranged_count = min(ranged_count, 15) # Era 10
	
	if wave_number >= 20:
		melee_count += 2
		fast_count += 1
		ranged_count += 1
	
	if wave_number >= 30:
		melee_count += 3
		fast_count += 2
		ranged_count += 2
	
	if wave_number >= 40:
		melee_count += 4
		fast_count += 3
		ranged_count += 3
	
	if melee_count > 0:
		config.enemies.append({"type": 0, "count": melee_count})
	if fast_count > 0:
		config.enemies.append({"type": 1, "count": fast_count})
	if ranged_count > 0:
		config.enemies.append({"type": 2, "count": ranged_count})
	
	return config

func start_next_wave():
	if current_wave >= max_waves:
		all_waves_completed.emit()
		return
	
	wave_in_progress = true
	print("Iniciando onda ", current_wave + 1)
	wave_started.emit(current_wave + 1)
	
	spawn_wave_enemies()

func spawn_wave_enemies():
	var current_config = generate_wave_config(current_wave + 1)
	var enemies_to_spawn = []
	
	for enemy_config in current_config.enemies:
		var enemy_type = enemy_config.type
		var count = enemy_config.count
		
		for i in range(count):
			enemies_to_spawn.append(enemy_type)
	
	enemies_to_spawn.shuffle()
	
	spawn_enemies_sequence(enemies_to_spawn)

func spawn_enemies_sequence(enemies_to_spawn: Array):
	for enemy_type in enemies_to_spawn:
		spawn_enemy(enemy_type)
		enemies_alive += 1
		
		await get_tree().create_timer(time_between_spawns).timeout

func spawn_enemy(enemy_type: int):
	if enemy_type >= enemy_scenes.size():
		print("Erro: Tipo de inimigo inválido: ", enemy_type)
		return
	
	var enemy_scene = enemy_scenes[enemy_type]
	if not enemy_scene:
		print("Erro: Cena do inimigo não encontrada para tipo: ", enemy_type)
		return
	
	var enemy = enemy_scene.instantiate()
	
	var spawn_point = get_random_spawn_point()
	enemy.global_position = spawn_point
	
	enemy.enemy_died.connect(_on_enemy_died)
	
	get_tree().root.add_child(enemy)

func get_random_spawn_point() -> Vector2:
	if spawn_points.is_empty():
		return Vector2.ZERO
	
	var valid_spawns = []
	
	for spawn_point in spawn_points:
		if player_ref:
			var distance = spawn_point.distance_to(player_ref.global_position)
			if distance > 80.0:
				valid_spawns.append(spawn_point)
	
	if valid_spawns.is_empty():
		valid_spawns = spawn_points
	
	return valid_spawns[randi() % valid_spawns.size()]

func _on_enemy_died(enemy):
	enemies_alive -= 1
	
	if enemies_alive <= 0 and wave_in_progress:
		complete_current_wave()

func complete_current_wave():
	wave_in_progress = false
	print("Onda ", current_wave + 1, " completada!")
	wave_completed.emit(current_wave + 1)
	
	await get_tree().create_timer(time_between_waves).timeout
	
	if current_wave + 1 < max_waves:
		current_wave += 1
		start_next_wave()
	else:
		print("Todas as ", max_waves, " ondas completadas!")
		all_waves_completed.emit()

func _on_spawn_timer_timeout():
	pass

func get_current_wave() -> int:
	return current_wave + 1

func get_enemies_alive() -> int:
	return enemies_alive

func is_wave_active() -> bool:
	return wave_in_progress
