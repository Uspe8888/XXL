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

var active_piece_scenes := []  # 存储当前轮次可用的棋子场景
@export var active_pieces_count := 5  # 每轮使用的棋子类型数量

# 预加载背景单元格场景
var back_cell=preload("res://scenes/background.tscn")

# 定义网格间距和单元格大小
@export var grid_gap : Vector2 = Vector2(2,2)
var cell_size: Vector2 = Vector2(16, 16)

# 新增：拖拽相关变量
var is_dragging := false
var dragged_piece: game_piece = null
var original_drag_position := Vector2.ZERO
var current_target_index := -1
var drag_start_index := -1
var drag_offset := Vector2.ZERO



# 场景加载时调用的函数
func _ready() -> void:
	# 初始化网格背景
	initialize_board()
	
	# 初始化棋子，将所有网格位置填充为空棋子
	for x in cols:
		for y in rows:
			spawn_chess(x, y, Piece_type.piece_type.empty)


# 处理输入事件
func _input(event: InputEvent) -> void:
	
	# 如果按下自定义动作 "my_action"，将棋子移动到指定位置
	if event.is_action_pressed("my_action"):
		var has_empty = false
		# 检查第一行是否有空位
		for x in cols:
			if pieces[Vector2(x, 0)].type == Piece_type.piece_type.empty:
				has_empty = true
				break

		if has_empty:
		# 如果有空位，调用生成方法
			create_top_piece()
		else:
			fill_bottom()
			await get_tree().create_timer(0.11).timeout

		
	# 如果按下 "fill" 动作，执行棋子下落逻辑
	if event.is_action_pressed("fill"):
		while true:
			if not await fill():
				break # 如果没有棋子可以下落，则退出循环
			await get_tree().create_timer(0.11).timeout	
	if event.is_action_pressed("step_fill"):
		fill()
	if event.is_action_pressed("fill_bottom"):
		fill_bottom()
		
	if event.is_action_pressed("check_matches"):
		check_matches()


	# 新增：处理鼠标拖拽事件
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# 鼠标按下，检查是否点中了第一行的棋子
				var mouse_pos = get_local_mouse_position()
				var grid_x = int(mouse_pos.x / (cell_size.x + grid_gap.x))
				var grid_y = int(mouse_pos.y / (cell_size.y + grid_gap.y))
				
				# 只处理第一行
				if grid_y == 0 and grid_x >= 0 and grid_x < cols:
					var piece = pieces[Vector2(grid_x, 0)]
					if piece and piece.type != Piece_type.piece_type.empty:
						# 开始拖拽
						is_dragging = true
						dragged_piece = piece
						drag_start_index = grid_x
						current_target_index = grid_x
						original_drag_position = piece.position
						drag_offset = piece.position - mouse_pos
						
						# 通知棋子开始拖拽
						piece.start_drag()
			else:
				# 鼠标释放
				if is_dragging and dragged_piece:
					# 结束拖拽
					is_dragging = false
					
					# 通知棋子结束拖拽
					dragged_piece.end_drag()
					
					# 计算目标位置
					var mouse_pos = get_global_mouse_position() + drag_offset
					var target_x = int(mouse_pos.x / (cell_size.x + grid_gap.x))
					target_x = clampi(target_x, 0, cols - 1)
					
					# 移动棋子到新位置
					move_piece_to_target(drag_start_index, target_x)
					
					# 重置状态
					dragged_piece = null
					drag_start_index = -1
					current_target_index = -1
					drag_offset = Vector2.ZERO
	
	# 处理鼠标移动
	elif event is InputEventMouseMotion and is_dragging and dragged_piece:
		var local_mouse_pos=get_local_mouse_position()
		# 更新棋子位置
		dragged_piece.drag_to_position(local_mouse_pos + drag_offset)
		
		# 计算目标位置
		var mouse_pos = event.global_position + drag_offset
		var target_x = int(mouse_pos.x / (cell_size.x + grid_gap.x))
		target_x = clampi(target_x, 0, cols - 1)
		
		# 如果目标位置改变，更新其他棋子的位置
		if target_x != current_target_index:
			current_target_index = target_x
			update_other_pieces_position()


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
	
	var cell:Node2D	
	# 如果类型为随机，则从非空棋子中随机选择
	if piece_type == Piece_type.piece_type.random:
		if active_piece_scenes.is_empty():
			select_active_pieces()  # 如果没有活跃棋子，重新选择
		cell = active_piece_scenes[randi() % active_piece_scenes.size()].instantiate()
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

	
func fill ()->bool:
	var move_piece:bool=false
	# 从倒数第二行开始向上遍历每一行
	for y in range(rows-2, -1, -1):
		for x in range(cols):
			var piece=pieces[Vector2(x, y)] # 当前棋子
			var piece_below=pieces[Vector2(x, y+1)] # 下方棋子
			# 如果下方棋子为空，则将当前棋子移动到下方
			if piece_below.type == Piece_type.piece_type.empty:
				#var piece_below_position:Vector2 = piece_below.position
				piece_below.queue_free() # 删除下方空棋子
				piece.move(piece_below) # 移动当前棋子
				pieces[Vector2(x, y+1)] = piece # 更新棋子位置
				spawn_chess(x, y, Piece_type.piece_type.empty) # 在原位置生成空棋子
				move_piece=true

	# 在顶部生成随机棋子
	for x in cols:
		var gae_piece=pieces[Vector2(x, 0)]
		#var piece_position=gae_piece.position
		if gae_piece.type == Piece_type.piece_type.empty:
			gae_piece.queue_free() # 删除顶部空棋子
			var new_piece= spawn_chess(x, -1, Piece_type.piece_type.random) # 生成随机棋子
			new_piece.move(gae_piece)
			pieces[Vector2(x, 0)] = new_piece # 更新棋子位置
			move_piece=true
	
	return move_piece
	
func create_top_piece():
	# 在顶部生成随机棋子
	for x in cols:
		var gae_piece=pieces[Vector2(x, 0)]
		if gae_piece.type == Piece_type.piece_type.empty:
			gae_piece.queue_free() # 删除顶部空棋子
			var new_piece= spawn_chess(x, -1, Piece_type.piece_type.random) # 生成随机棋子
			new_piece.move(gae_piece)
			pieces[Vector2(x, 0)] = new_piece # 更新棋子位置
			

func check_matches() -> bool:
	var has_matches = false
	var matches = []

	# 检查水平方向的匹配
	for y in rows:
		var current_type = null
		var current_match = []

		for x in cols:
			var piece = pieces[Vector2(x, y)]

			if piece.type == current_type and piece.type != Piece_type.piece_type.empty:
				current_match.append(Vector2(x, y))
			else:
				if current_match.size() >= 3:
					matches.append_array(current_match)
					has_matches = true
				current_match = [Vector2(x, y)]
				current_type = piece.type

		if current_match.size() >= 3:
			matches.append_array(current_match)
			has_matches = true

	# 检查垂直方向的匹配
	for x in cols:
		var current_type = null
		var current_match = []

		for y in rows:
			var piece = pieces[Vector2(x, y)]

			if piece.type == current_type and piece.type != Piece_type.piece_type.empty:
				current_match.append(Vector2(x, y))
			else:
				if current_match.size() >= 3:
					matches.append_array(current_match)
					has_matches = true
				current_match = [Vector2(x, y)]
				current_type = piece.type

		if current_match.size() >= 3:
			matches.append_array(current_match)
			has_matches = true

	# 消除匹配的棋子
	if has_matches:
		for pos in matches:
			var piece = pieces[pos]
			piece.queue_free()
			spawn_chess(pos.x, pos.y, Piece_type.piece_type.empty)

	return has_matches
	
	
func select_active_pieces() -> void: 
	active_piece_scenes.clear()
	# 首先复制除empty外的所有棋子场景
	var available_scenes = piece_scenes.slice(1, piece_scenes.size())
	# 随机打乱数组
	available_scenes.shuffle()
	# 选择指定数量的棋子类型
	active_piece_scenes = available_scenes.slice(0, active_pieces_count)
	
	
func fill_bottom() -> bool:#棋子落到底
	var moved = false
	# 从下往上、从左往右遍历棋盘
	for x in cols:
		for y in range(rows - 2, -1, -1):
			var current_piece = pieces[Vector2(x, y)]
			# 跳过空棋子
			if current_piece.type == Piece_type.piece_type.empty:
				continue

			# 找到当前列最下方的空位置
			var bottom_y = y
			for check_y in range(rows - 1, y, -1):
				if pieces[Vector2(x, check_y)].type == Piece_type.piece_type.empty:
					bottom_y = check_y
					break

			# 如果找到了更下方的空位置
			if bottom_y != y:
				# 移动棋子到目标位置
				var target_piece = pieces[Vector2(x, bottom_y)]
				target_piece.queue_free()
				current_piece.move(target_piece)
				pieces[Vector2(x, bottom_y)] = current_piece
				# 在原位置生成空棋子
				pieces[Vector2(x, y)] = spawn_chess(x, y, Piece_type.piece_type.empty)
				moved = true

	return moved

func update_other_pieces_position():
 	# 创建临时数组存储原始顺序
	var original_pieces = []
	for x in cols:
		original_pieces.append(pieces[Vector2(x, 0)])
			
	# 计算新的位置
	for x in cols:
		if x == drag_start_index:
			continue
			
		var piece = original_pieces[x]
		var new_x = x
			
		# 确定每个棋子的新位置
		if x > current_target_index and x < drag_start_index:
			new_x = x + 1
		elif x < current_target_index and x > drag_start_index:
			new_x = x - 1
			
		# 移动棋子到新位置
		if piece and piece != dragged_piece:
			var target_pos = get_world_position(new_x, 0)
			var tween = create_tween()
			tween.tween_property(piece, "position", target_pos, 0.1)

# 新增：移动棋子到目标位置（实际更新数据结构）
func move_piece_to_target(start_index: int, target_index: int):
	if start_index == target_index:
		# 如果位置没变，直接返回
		dragged_piece.position = original_drag_position
		return
	
	# 创建一个临时数组表示第一行的棋子
	var temp_row = []
	for i in cols:
		temp_row.append(pieces[Vector2(i, 0)])
	
	# 移除拖动的棋子
	var moved_piece = temp_row[start_index]
	temp_row.remove_at(start_index)
	
	# 插入到目标位置
	temp_row.insert(target_index, moved_piece)
	
	# 更新数据结构
	for x in cols:
		var piece = temp_row[x]
		pieces[Vector2(x, 0)] = piece
		
		# 移动棋子到新位置（如果位置改变）
		if piece.position != get_world_position(x, 0):
			var target = Node2D.new()
			target.position = get_world_position(x, 0)
			piece.move(target)
	
	# 检查是否有匹配
	await get_tree().create_timer(0.2).timeout
	check_matches()
