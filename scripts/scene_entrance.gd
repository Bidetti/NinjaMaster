extends Area2D

# @export permite definir o valor da variável pelo Inspetor da cena.
@export var next_scene: String

# Função chamada quando um corpo entra na área (sinal "body_entered").
func _on_body_entered(body: Node2D) -> void:
# Verifica se o objeto que colidiu com a área tem o nome de classe "Player"
	print(body)
	if body is Player:
		# Realiza a troca de cena.
		print("Oia o player")
		get_tree().change_scene_to_file.call_deferred(next_scene)
