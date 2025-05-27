extends Node2D

@onready var wave_manager: WaveManager
@onready var ui_layer: CanvasLayer

var tutorial_shown: bool = false
var game_started: bool = false

func _ready():
	setup_ui()
	setup_wave_manager()
	connect_signals()
	
	if not has_played_before():
		show_tutorial()
	else:
		start_game()

func has_played_before() -> bool:
	var save_path = "user://game_progress.save"
	var save_file = FileAccess.open(save_path, FileAccess.READ)
	if save_file:
		save_file.close()
		print("Arquivo de progresso encontrado em: ", save_path)
		print("Caminho absoluto: ", ProjectSettings.globalize_path(save_path))
		return true
	else:
		print("Primeiro jogo - nenhum arquivo de progresso encontrado em: ", save_path)
		return false

func mark_as_played():
	var save_path = "user://game_progress.save"
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	if save_file:
		save_file.store_string("played")
		save_file.close()
		print("Progresso salvo em: ", save_path)
		print("Caminho absoluto: ", ProjectSettings.globalize_path(save_path))

func show_tutorial():
	tutorial_shown = true
	
	var overlay = UIPanelCreator.create_overlay(self)
	overlay.name = "TutorialOverlay"
	ui_layer.add_child(overlay)
	
	var tutorial_panel = create_tutorial_panel()
	ui_layer.add_child(tutorial_panel)
	
	if wave_manager:
		wave_manager.set_process(false)
		wave_manager.set_physics_process(false)

func create_tutorial_panel() -> Control:
	var panel = UIPanelCreator.create_styled_panel(Vector2(600, 550), self)
	panel.name = "TutorialPanel"
	
	var vbox = VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "TUTORIAL - CONTROLES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color.YELLOW)
	vbox.add_child(title)
	
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(spacer1)
	
	var instructions = [
		"🖱️ BOTÃO ESQUERDO DO MOUSE - Atirar",
		"⌨️ W A S D - Movimentação",
		"⚡ SHIFT - Sprint (correr)",
		"🔄 R - Recarregar arma",
		"🎯 MOUSE - Mirar direção"
	]
	
	for instruction in instructions:
		var label = Label.new()
		label.text = instruction
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_color", Color.WHITE)
		vbox.add_child(label)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer2)
	
	var objective_title = Label.new()
	objective_title.text = "OBJETIVO:"
	objective_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_title.add_theme_font_size_override("font_size", 28)
	objective_title.add_theme_color_override("font_color", Color.CYAN)
	vbox.add_child(objective_title)
	
	var objective = Label.new()
	objective.text = "Sobreviva às ondas de inimigos!"
	objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective.add_theme_font_size_override("font_size", 20)
	objective.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(objective)
	
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 25)
	vbox.add_child(spacer3)
	
	var start_button = UIPanelCreator.create_styled_button("INICIAR JOGO")
	start_button.pressed.connect(_on_start_game_pressed)
	
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_child(start_button)
	vbox.add_child(button_container)
	
	return panel

func show_wave_complete_message(wave_number: int):
	if not ui_layer:
		return
		
	var overlay = UIPanelCreator.create_overlay(self)
	overlay.name = "WaveCompleteOverlay"
	ui_layer.add_child(overlay)
	
	var panel = UIPanelCreator.create_styled_panel(Vector2(400, 300), self)
	panel.name = "WaveCompletePanel"
	
	var vbox = VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer1)
	
	var message_label = Label.new()
	message_label.text = "ONDA " + str(wave_number) + " COMPLETA!"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 32)
	message_label.add_theme_color_override("font_color", Color.GREEN)
	vbox.add_child(message_label)
	
	var bonus_label = Label.new()
	bonus_label.text = "Bônus: " + str(wave_number * 50) + " pontos"
	bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonus_label.add_theme_font_size_override("font_size", 20)
	bonus_label.add_theme_color_override("font_color", Color.YELLOW)
	vbox.add_child(bonus_label)
	
	ui_layer.add_child(panel)
	
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(func(): 
		overlay.queue_free()
		panel.queue_free()
	)

func _on_start_game_pressed():
	hide_tutorial()
	start_game()
	mark_as_played()

func hide_tutorial():
	if ui_layer.has_node("TutorialOverlay"):
		ui_layer.get_node("TutorialOverlay").queue_free()
	if ui_layer.has_node("TutorialPanel"):
		ui_layer.get_node("TutorialPanel").queue_free()

func start_game():
	game_started = true
	if wave_manager:
		wave_manager.set_process(true)
		wave_manager.set_physics_process(true)
		wave_manager.start_waves()

func setup_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	create_ui_elements()

func setup_wave_manager():
	var wave_manager_scene = preload("res://scenes/WaveManager.tscn")
	wave_manager = wave_manager_scene.instantiate()
	add_child(wave_manager)
	
	wave_manager.spawn_points = [
		Vector2(150, -100),   # Norte
		Vector2(150, 100),    # Sul
		Vector2(-150, -100),  # Noroeste
		Vector2(-150, 100),   # Sudoeste
		Vector2(200, 0),      # Leste
		Vector2(-200, 0),     # Oeste
		Vector2(0, -150),     # Norte centro
		Vector2(0, 150)       # Sul centro
	]
	
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_completed.connect(_on_wave_completed)
	wave_manager.all_waves_completed.connect(_on_all_waves_completed)
	
	wave_manager.set_process(false)
	wave_manager.set_physics_process(false)

func create_ui_elements():
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

func connect_signals():
	GameScene.score_changed.connect(_on_score_changed)

func _process(_delta):
	update_ui()

func update_ui():
	if not ui_layer or not wave_manager:
		return
	
	var wave_label = ui_layer.get_node("WaveLabel")
	var enemies_label = ui_layer.get_node("EnemiesLabel")
	
	if wave_label:
		if game_started:
			wave_label.text = "Onda: " + str(wave_manager.get_current_wave())
		else:
			wave_label.text = "Aguardando início..."
	
	if enemies_label:
		if game_started:
			enemies_label.text = "Inimigos: " + str(wave_manager.get_enemies_alive())
		else:
			enemies_label.text = "Inimigos: -"

func _on_score_changed(new_score: int):
	if ui_layer and ui_layer.has_node("ScoreLabel"):
		var score_label = ui_layer.get_node("ScoreLabel")
		score_label.text = "Pontuação: " + str(new_score)

func _on_wave_started(wave_number: int):
	print("Iniciando onda ", wave_number)
	
	if ui_layer and ui_layer.has_node("WaveLabel"):
		var wave_label = ui_layer.get_node("WaveLabel")
		animate_wave_label(wave_label)

func animate_wave_label(label: Label):
	var tween = create_tween()
	tween.tween_property(label, "modulate", Color.YELLOW, 0.5)
	tween.tween_property(label, "modulate", Color.WHITE, 0.5)

func _on_wave_completed(wave_number: int):
	print("Onda ", wave_number, " completada!")
	GameScene.add_score(wave_number * 50)
	
	show_wave_complete_message(wave_number)

func _on_all_waves_completed():
	print("Todas as ondas completadas! Parabéns!")
	GameScene.add_score(500)
	
	var overlay = UIPanelCreator.create_overlay(self)
	overlay.name = "AllWavesCompleteOverlay"
	ui_layer.add_child(overlay)
	
	var panel = UIPanelCreator.create_styled_panel(Vector2(500, 400), self)
	panel.name = "AllWavesCompletePanel"
	
	var vbox = VBoxContainer.new()
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(spacer1)
	
	var title_label = Label.new()
	title_label.text = "PARABÉNS!"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 42)
	title_label.add_theme_color_override("font_color", Color.GOLD)
	vbox.add_child(title_label)
	
	var completion_label = Label.new()
	completion_label.text = "TODAS AS ONDAS COMPLETADAS!"
	completion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	completion_label.add_theme_font_size_override("font_size", 24)
	completion_label.add_theme_color_override("font_color", Color.GREEN)
	vbox.add_child(completion_label)
	
	var bonus_label = Label.new()
	bonus_label.text = "Bônus Final: 500 pontos"
	bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonus_label.add_theme_font_size_override("font_size", 20)
	bonus_label.add_theme_color_override("font_color", Color.YELLOW)
	vbox.add_child(bonus_label)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer2)
	
	var restart_button = UIPanelCreator.create_styled_button("JOGAR NOVAMENTE")
	restart_button.pressed.connect(func(): get_tree().reload_current_scene())
	
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_child(restart_button)
	vbox.add_child(button_container)
	
	ui_layer.add_child(panel)
	
	await get_tree().create_timer(2.0).timeout
