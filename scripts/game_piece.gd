extends Node2D

class_name game_piece

@export var type=Piece_type.piece_type.bat
var is_dragging:=false
var original_position:=Vector2.ZERO
var original_grid_pos:=Vector2.ZERO

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

# 新增：开始拖动棋子
func start_drag():
	is_dragging = true
	original_position = position
	z_index = 10  # 提升层级，确保在顶部
	# 保存原始网格位置
	original_grid_pos = Vector2(
		int(original_position.x / (16 + 2)), 
		int(original_position.y / (16 + 2))
	)
	
	# 新增：结束拖动
func end_drag():
	is_dragging = false
	z_index = 0  # 恢复层级

# 新增：跟随鼠标移动
func drag_to_position(pos: Vector2):
	position=pos
	
