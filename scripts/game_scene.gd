extends Node2D

var player_hp: int = 4
var current_score: int = 0

@onready var wave_manager: WaveManager
@onready var ui_layer: CanvasLayer

func _ready():
	var wave_manager_scene = preload("res://scenes/WaveManager.tscn")
	wave_manager = wave_manager_scene.instantiate()
	add_child(wave_manager)
	
	setup_wave_manager()
	setup_ui()

func setup_wave_manager():
	wave_manager.spawn_points = [
		Vector2(300, -200),   # Norte
		Vector2(300, 200),    # Sul
		Vector2(-300, -200),  # Noroeste
		Vector2(-300, 200),   # Sudoeste
		Vector2(500, 0),      # Leste
		Vector2(-500, 0),     # Oeste
		Vector2(0, -300),     # Norte centro
		Vector2(0, 300)       # Sul centro
	]
	
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_completed.connect(_on_wave_completed)
	wave_manager.all_waves_completed.connect(_on_all_waves_completed)

func setup_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	var wave_label = Label.new()
	wave_label.name = "WaveLabel"
	wave_label.text = "Preparando primeira onda..."
	wave_label.position = Vector2(20, 20)
	wave_label.add_theme_font_size_override("font_size", 20)
	ui_layer.add_child(wave_label)
	
	var enemies_label = Label.new()
	enemies_label.name = "EnemiesLabel"
	enemies_label.text = "Inimigos: 0"
	enemies_label.position = Vector2(20, 50)
	enemies_label.add_theme_font_size_override("font_size", 16)
	ui_layer.add_child(enemies_label)
	
	var score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "Pontuação: 0"
	score_label.position = Vector2(20, 80)
	score_label.add_theme_font_size_override("font_size", 16)
	ui_layer.add_child(score_label)

func _process(_delta):
	update_ui()

func update_ui():
	if not ui_layer or not wave_manager:
		return
	
	var wave_label = ui_layer.get_node("WaveLabel")
	var enemies_label = ui_layer.get_node("EnemiesLabel")
	var score_label = ui_layer.get_node("ScoreLabel")
	
	wave_label.text = "Onda: " + str(wave_manager.get_current_wave())
	enemies_label.text = "Inimigos: " + str(wave_manager.get_enemies_alive())
	score_label.text = "Pontuação: " + str(current_score)

func _on_wave_started(wave_number: int):
	print("Iniciando onda ", wave_number)
	
	if ui_layer and ui_layer.has_node("WaveLabel"):
		var wave_label = ui_layer.get_node("WaveLabel")
		var tween = create_tween()
		tween.tween_property(wave_label, "modulate", Color.YELLOW, 0.5)
		tween.tween_property(wave_label, "modulate", Color.WHITE, 0.5)

func _on_wave_completed(wave_number: int):
	print("Onda ", wave_number, " completada!")
	current_score += wave_number * 50
	
	show_wave_complete_message(wave_number)

func _on_all_waves_completed():
	print("Todas as ondas completadas! Parabéns!")
	current_score += 500
	
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/GameScene/dungeon_scene.tscn")

func show_wave_complete_message(wave_number: int):
	if not ui_layer:
		return
		
	var message_label = Label.new()
	message_label.text = "ONDA " + str(wave_number) + " COMPLETA!"
	message_label.position = Vector2(400, 300)
	message_label.add_theme_font_size_override("font_size", 32)
	message_label.modulate = Color.GREEN
	ui_layer.add_child(message_label)
	
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(func(): message_label.queue_free())

func add_score(points: int):
	current_score += points
