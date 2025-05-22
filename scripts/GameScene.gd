extends Node

signal player_hp_changed(current_hp)
signal score_changed(new_score)

var player_hp: int = 4 : set = set_player_hp
var current_score: int = 0 : set = set_current_score

func set_player_hp(value: int):
	var old_hp = player_hp
	player_hp = clamp(value, 0, 4)
	if old_hp != player_hp:
		player_hp_changed.emit(player_hp)

func set_current_score(value: int):
	var old_score = current_score
	current_score = max(value, 0)
	if old_score != current_score:
		score_changed.emit(current_score)

func add_score(points: int):
	self.current_score += points

func reset_game():
	player_hp = 4
	current_score = 0
