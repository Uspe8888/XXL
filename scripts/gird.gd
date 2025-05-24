extends Node2D

class_name gird

# 导出变量，定义棋子场景数组，包含不同类型的棋子
@export var piece_scenes:=[
	preload("res://pieces/empty.tscn"),
	preload("res://pieces/farmer.tscn"),
	preload("res://pieces/ghost.tscn"),
	preload("res://pieces/magician.tscn"),
	preload("res://pieces/mouse.tscn"),
	preload("res://pieces/warrior.tscn"),
	preload("res://pieces/woman.tscn"),
	preload("res://pieces/bat.tscn")]

# 定义空棋子的场景路径
@export var empty_piece="res://pieces/emptypiece.tscn"

# 背景节点，用于存储网格背景
@onready var back_ground=$back_ground

# 棋子字典，用于存储棋子实例
var piece_dict:Dictionary={}
var pieces={}


# 定义网格的列数和行数
var cols:int=9 # 列
var rows:int=9 # 行

#caocaocao

# 预加载背景单元格场景
var back_cell=preload("res://scenes/background.tscn")

# 定义网格间距和单元格大小
@export var grid_gap : Vector2 = Vector2(2,2)
var cell_size: Vector2 = Vector2(16, 16)

# 场景加载时调用的函数
func _ready() -> void:
	# 初始化网格背景
	initialize_board()
	
	# 初始化棋子，将所有网格位置填充为空棋子
	for x in cols:
		for y in rows:
			spawn_chess(x, y, Piece_type.piece_type.empty)

# 每帧调用的函数（当前未使用）
func _process(delta: float) -> void:
	pass

# 处理输入事件
func _input(event: InputEvent) -> void:
	# 如果按下自定义动作 "my_action"，将棋子移动到指定位置
	if event.is_action_pressed("my_action"):
		pieces[Vector2(5,5)].move(Vector2(6,5))
		
	# 如果按下 "fill" 动作，执行棋子下落逻辑
	if event.is_action_pressed("fill"):
		# 从倒数第二行开始向上遍历每一行
		for y in range(rows-2, -1, -1):
			for x in range(cols):
				var piece=pieces[Vector2(x, y)] # 当前棋子
				var piece_below=pieces[Vector2(x, y+1)] # 下方棋子
				# 如果下方棋子为空，则将当前棋子移动到下方
				if piece_below.type == Piece_type.piece_type.empty:
					var piece_below_position:Vector2 = piece_below.position
					piece_below.queue_free() # 删除下方空棋子
					piece.move(piece_below_position) # 移动当前棋子
					pieces[Vector2(x, y+1)] = piece # 更新棋子位置
					spawn_chess(x, y, Piece_type.piece_type.empty) # 在原位置生成空棋子
					
		# 在顶部生成随机棋子
		for x in cols:
			var gae_piece=pieces[Vector2(x, 0)]
			var piece_position=gae_piece.position
			if gae_piece.type == Piece_type.piece_type.empty:
				gae_piece.queue_free() # 删除顶部空棋子
				var new_piece= spawn_chess(x, -1, Piece_type.piece_type.random) # 生成随机棋子
				new_piece.move(piece_position)
				pieces[Vector2(x, 0)] = new_piece # 更新棋子位置
				

# 初始化网格背景
func initialize_board() -> void:	
	for y in cols:
		for x in rows:
			# 实例化背景单元格
			var cell = back_cell.instantiate()
			# 设置单元格位置
			cell.position = Vector2(x * (cell_size.x + grid_gap.x), 
			y * (cell_size.y + grid_gap.y))
			# 将单元格添加到背景节点
			back_ground.add_child(cell)

# 生成棋子
func spawn_chess(x:int, y:int, piece_type: Piece_type.piece_type=Piece_type.piece_type.random):
	var cell
	
	# 如果类型为随机，则从非空棋子中随机选择
	if piece_type == Piece_type.piece_type.random:
		var non_empty_scenes = piece_scenes.slice(1, piece_scenes.size())
		cell = non_empty_scenes[randi() % non_empty_scenes.size()].instantiate()
	else:
		# 否则生成空棋子
		cell = piece_scenes[0].instantiate()
		
	# 设置棋子位置
	cell.position = get_world_position(x, y)
	add_child(cell) # 添加到场景树
	pieces[Vector2(x, y)] = cell # 更新棋子字典
	return cell

# 将网格坐标转换为世界坐标
func get_world_position(x, y) -> Vector2:
	return Vector2(x * (cell_size.x + grid_gap.x), 
			y * (cell_size.y + grid_gap.y))
