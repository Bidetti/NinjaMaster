extends Node2D
class_name WaveManager

signal wave_started(wave_number)
signal wave_completed(wave_number)
signal all_waves_completed

@export var enemy_scenes: Array[PackedScene] = []
@export var spawn_points: Array[Vector2] = []
@export var time_between_waves: float = 3.0
@export var time_between_spawns: float = 0.5

var current_wave: int = 0
var enemies_alive: int = 0
var wave_in_progress: bool = false
var player_ref: Player

var wave_configs = [
	{
		"enemies": [
			{"type": 0, "count": 3}
		]
	},
	{
		"enemies": [
			{"type": 0, "count": 4},
			{"type": 1, "count": 2}
		]
	},
	{
		"enemies": [
			{"type": 0, "count": 3},
			{"type": 1, "count": 3},
			{"type": 2, "count": 2}
		]
	},
	{
		"enemies": [
			{"type": 0, "count": 5},
			{"type": 1, "count": 4},
			{"type": 2, "count": 3}
		]
	},
	{
		"enemies": [
			{"type": 0, "count": 6},
			{"type": 1, "count": 5},
			{"type": 2, "count": 4}
		]
	}
]

@onready var spawn_timer: Timer = $SpawnTimer
@onready var wave_timer: Timer = $WaveTimer

func _ready():
	player_ref = get_tree().get_first_node_in_group("player")
	
	spawn_timer.wait_time = time_between_spawns
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	wave_timer.wait_time = time_between_waves
	wave_timer.timeout.connect(_on_wave_timer_timeout)
	
	if spawn_points.is_empty():
		generate_spawn_points()
	
	if enemy_scenes.is_empty():
		load_default_enemy_scenes()
	
	await get_tree().create_timer(2.0).timeout
	start_next_wave()

func generate_spawn_points():
	var map_center = Vector2.ZERO
	var spawn_radius = 300.0
	
	for i in range(8):
		var angle = (i * TAU) / 8.0
		var spawn_point = map_center + Vector2.from_angle(angle) * spawn_radius
		spawn_points.append(spawn_point)

func load_default_enemy_scenes():
	enemy_scenes = [
		preload("res://scenes/enemy/MeleeEnemy.tscn"),
		preload("res://scenes/enemy/FastEnemy.tscn"),
		preload("res://scenes/enemy/RangedEnemy.tscn")
	]

func start_next_wave():
	if current_wave >= wave_configs.size():
		all_waves_completed.emit()
		return
	
	wave_in_progress = true
	wave_started.emit(current_wave + 1)
	
	print("Iniciando onda ", current_wave + 1)
	
	spawn_wave_enemies()

func spawn_wave_enemies():
	var current_config = wave_configs[current_wave]
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
			if distance > 150.0:
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
	wave_completed.emit(current_wave + 1)
	
	print("Onda ", current_wave + 1, " completada!")
	
	current_wave += 1
	
	wave_timer.start()

func _on_wave_timer_timeout():
	start_next_wave()

func _on_spawn_timer_timeout():
	pass

func get_current_wave() -> int:
	return current_wave + 1

func get_enemies_alive() -> int:
	return enemies_alive

func is_wave_active() -> bool:
	return wave_in_progress
