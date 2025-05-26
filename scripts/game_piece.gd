extends Node2D

class_name game_piece

@export var type=Piece_type.piece_type.bat

#@onready var chess: gird = get_node("/root/Game/chess")



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func move(target:Node2D):
	var end_pos=target
	var tween := create_tween()
	tween.tween_property(self, "position", end_pos.position, 0.1)
