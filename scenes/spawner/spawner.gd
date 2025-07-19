extends Node2D

##################################################
const BOUNDARY_SIZE: Vector2 = Vector2(360.0, 360.0)
const OBJECT_SIZE: Vector2 = Vector2(2.0, 2.0)
const SPAWN_BATCH_SIZE: int = 100
const MOVING_SPEED: float = 10.0
const CELL_SIZE: int = 6

var spawn_timer_node: Timer

var objects: Array = []
var diagonal_directions: Array = [
	Vector2(-1, 1), Vector2(-1, -1), Vector2(1, 1), Vector2(1, -1)
	]
var cell_map: Dictionary = {}
var frame_log: Dictionary = {}

##################################################
func _ready() -> void:
	spawn_timer_node = $SpawnTimer
	spawn_timer_node.wait_time = 1.0
	spawn_timer_node.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer_node.start()
	
	cell_map.clear()
	for y in range(int(BOUNDARY_SIZE.y / CELL_SIZE)):
		for x in range(int(BOUNDARY_SIZE.x / CELL_SIZE)):
			cell_map[Vector2i(x, y)] = []

##################################################
func _process(delta: float) -> void:
	for i in range(objects.size()):
		objects[i]["position"] += objects[i]["velocity"] * delta
		
		if objects[i]["position"].x < 0.0 or objects[i]["position"].x > BOUNDARY_SIZE.x or \
		objects[i]["position"].y < 0.0 or objects[i]["position"].y > BOUNDARY_SIZE.y:
			objects[i]["position"] = Vector2(randf_range(0.0, BOUNDARY_SIZE.x), randf_range(0.0, BOUNDARY_SIZE.y))
		
		if objects[i]["position"].x <= (OBJECT_SIZE.x / 2) or \
		objects[i]["position"].x >= BOUNDARY_SIZE.x - (OBJECT_SIZE.x / 2):
			objects[i]["velocity"].x *= -1
		
		if objects[i]["position"].y <= (OBJECT_SIZE.x / 2) or \
		objects[i]["position"].y >= BOUNDARY_SIZE.y - (OBJECT_SIZE.x / 2):
			objects[i]["velocity"].y *= -1
	
	_rebuild_cell_map()
	_check_collision()
	_save_fps_log()
	
	queue_redraw()

##################################################
func _draw() -> void:
	for obj in objects:
		var center_position: Vector2 = obj["position"] - (OBJECT_SIZE / 2)
		draw_rect(Rect2(center_position, OBJECT_SIZE), Color.AQUA)

##################################################
func _on_spawn_timer_timeout() -> void:
	GameManager.set_object_count(GameManager.get_object_count() + SPAWN_BATCH_SIZE)
	
	for i in range(SPAWN_BATCH_SIZE):
		var pos: Vector2 = \
		Vector2(randf_range(0.0, BOUNDARY_SIZE.x), randf_range(0.0, BOUNDARY_SIZE.y))
		diagonal_directions.shuffle()
		var dir: Vector2 = diagonal_directions.front()
		var obj: Dictionary = {
			"position": pos,
			"velocity": dir.normalized() * MOVING_SPEED
		}
		objects.append(obj)

##################################################
func _rebuild_cell_map() -> void:
	for key in cell_map.keys():
		cell_map[key].clear()
	
	for i in range(objects.size()):
		var pos: Vector2 = objects[i]["position"]
		var cell = _get_cell_position(pos)
		
		if cell_map.has(cell):
			cell_map[cell].append(i)

##################################################
func _check_collision() -> void:
	for cell_key in cell_map.keys():
		var neighbor_cells = _get_neighbor_cells(cell_key)
		var index_array: Array = []
		
		for n_cell in neighbor_cells:
			for idx in cell_map[n_cell]:
				index_array.append(idx)
		
		for i in range(index_array.size()):
			for j in range(i + 1, index_array.size()):
				var idx_a = index_array[i]
				var idx_b = index_array[j]

				var a = objects[idx_a]
				var b = objects[idx_b]

				var rect_a = Rect2(a["position"] - (OBJECT_SIZE / 2), OBJECT_SIZE)
				var rect_b = Rect2(b["position"] - (OBJECT_SIZE / 2), OBJECT_SIZE)

				if rect_a.intersects(rect_b):
					var va = objects[idx_a]["velocity"]
					var vb = objects[idx_b]["velocity"]

					objects[idx_a]["velocity"] = -va
					objects[idx_b]["velocity"] = -vb

##################################################
func _get_cell_position(position_value: Vector2) -> Vector2i:
	return Vector2i(floor(position_value.x / CELL_SIZE), \
	floor(position_value.y / CELL_SIZE))

##################################################
func _get_neighbor_cells(center_cell: Vector2i) -> Array:
	var return_array = []
	return_array.append(Vector2i(center_cell.x, center_cell.y))
	return_array.append(Vector2i(center_cell.x + 1, center_cell.y))
	return_array.append(Vector2i(center_cell.x, center_cell.y + 1))
	return_array.append(Vector2i(center_cell.x + 1, center_cell.y + 1))
	
	for i in range(return_array.size() - 1, -1, -1):
		if return_array[i].x < 0 or \
		return_array[i].x >= int(BOUNDARY_SIZE.x / CELL_SIZE) or \
		return_array[i].y < 0 or \
		return_array[i].y >= int(BOUNDARY_SIZE.y / CELL_SIZE):
			return_array.remove_at(i)
	
	return return_array

##################################################
func _save_fps_log() -> void:
	frame_log[GameManager.get_object_count()] = Engine.get_frames_per_second()
	
	var file = FileAccess.open("user://fps_log.txt", FileAccess.WRITE)
	if file:
		for sec in frame_log.keys():
			file.store_line("%d, %d" % [sec, frame_log[sec]])
		file.close()
