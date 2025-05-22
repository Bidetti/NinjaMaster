extends Node2D

var player_hp: int = 4
var boss_spawned: bool = false

@onready var boss_scene = preload("res://scenes/enemy/BossEnemy.tscn")
@onready var ui_layer: CanvasLayer

func _ready():
	setup_ui()
	
	await get_tree().create_timer(2.0).timeout
	spawn_boss()

func setup_ui():
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	var boss_label = Label.new()
	boss_label.name = "BossLabel"
	boss_label.text = "BOSS FIGHT"
	boss_label.position = Vector2(400, 50)
	boss_label.add_theme_font_size_override("font_size", 32)
	boss_label.modulate = Color.RED
	ui_layer.add_child(boss_label)
	
	var boss_hp_label = Label.new()
	boss_hp_label.name = "BossHPLabel"
	boss_hp_label.text = "Boss HP: 30/30"
	boss_hp_label.position = Vector2(400, 100)
	boss_hp_label.add_theme_font_size_override("font_size", 20)
	ui_layer.add_child(boss_hp_label)

func spawn_boss():
	if boss_spawned:
		return
	
	boss_spawned = true
	var boss = boss_scene.instantiate()
	
	boss.global_position = Vector2(0, -100)
	
	boss.boss_defeated.connect(_on_boss_defeated)
	boss.enemy_died.connect(_on_boss_died)
	
	add_child(boss)
	
	show_boss_intro()

func show_boss_intro():
	var intro_label = Label.new()
	intro_label.text = "UM INIMIGO PODEROSO APARECEU!"
	intro_label.position = Vector2(300, 250)
	intro_label.add_theme_font_size_override("font_size", 24)
	intro_label.modulate = Color.RED
	ui_layer.add_child(intro_label)
	
	var tween = create_tween()
	tween.tween_property(intro_label, "modulate:a", 0.0, 3.0)
	tween.tween_callback(func(): intro_label.queue_free())

func _process(_delta):
	update_boss_ui()

func update_boss_ui():
	if not ui_layer:
		return
	
	var boss_hp_label = ui_layer.get_node("BossHPLabel")
	var boss = get_boss_reference()
	
	if boss and boss_hp_label:
		boss_hp_label.text = "Boss HP: " + str(boss.current_hp) + "/" + str(boss.max_hp)
		
		if boss.current_hp <= boss.phase_2_hp_threshold:
			boss_hp_label.modulate = Color.ORANGE
		if boss.current_hp <= 10:
			boss_hp_label.modulate = Color.RED

func get_boss_reference() -> BossEnemy:
	var bosses = get_tree().get_nodes_in_group("boss")
	if bosses.size() > 0:
		return bosses[0]
	return null

func _on_boss_defeated():
	print("Boss derrotado!")
	show_victory_message()
	
	await get_tree().create_timer(5.0).timeout
	get_tree().change_scene_to_file("res://scenes/GameScene/game_scene.tscn")

func _on_boss_died(boss):
	print("Boss morreu!")
	if get_parent().has_method("add_score"):
		get_parent().add_score(500)

func show_victory_message():
	var victory_label = Label.new()
	victory_label.text = "VITÓRIA!\nBOSS DERROTADO!"
	victory_label.position = Vector2(350, 200)
	victory_label.add_theme_font_size_override("font_size", 36)
	victory_label.modulate = Color.GOLD
	victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_layer.add_child(victory_label)
	
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(victory_label, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_property(victory_label, "scale", Vector2(1.0, 1.0), 0.5)
