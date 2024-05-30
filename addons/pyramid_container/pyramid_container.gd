@tool
@icon("pyramid_container.svg")
class_name PyramidContainer extends Container
## A container that arranges its child controls in the shape of a pyramid.

enum Direction {
	UP    = 0,
	RIGHT = 1,
	DOWN  = 2,
	LEFT  = 3
}

@export var direction := Direction.UP:
	set(value):
		direction = value
		if is_inside_tree():
			queue_sort()


@export_group("Line Drawing", "draw_")
@export var draw_enabled := false:
	set(value):
		draw_enabled = value
		if is_inside_tree():
			queue_redraw()

@export_range(1, 10, 1, "or_greater", "suffix:px") var draw_width := 3.0:
	set(value):
		draw_width = value
		if is_inside_tree():
			queue_redraw()

@export_range(0, 50, 1, "or_greater", "suffix:px") var draw_shortened := 10:
	set(value):
		draw_shortened = value
		if is_inside_tree():
			queue_redraw()

@export var draw_color := Color.WHITE:
	set(value):
		draw_color = value
		if is_inside_tree():
			queue_redraw()

@export var draw_antialiased := true:
	set(value):
		draw_antialiased = value
		if is_inside_tree():
			queue_redraw()


# for internal use only!
var _num_layers : int
var _num_children : int
var _biggest_included_power_of_two : int


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_resort()
		queue_redraw()


func _resort() -> void:
	_num_children = get_child_count()

	_num_layers = 0
	var remaining_children := _num_children
	_biggest_included_power_of_two = int(log(_num_children) / log(2))
	while remaining_children > 0:
		remaining_children -= 2 ** (_biggest_included_power_of_two - _num_layers)
		_num_layers += 1

	var layer := 0
	var pos_in_layer := 0
	var num_nodes_in_layer := 2 ** _biggest_included_power_of_two

	for i in range(_num_children):
		var factor := layer
		if direction == Direction.LEFT or direction == Direction.UP:
			factor = _num_layers - layer - 1

		match direction:
			# horizontal directions
			Direction.LEFT, Direction.RIGHT:
				var item_size := Vector2(size.x / float(_num_layers), size.y / float(num_nodes_in_layer))
				fit_child_in_rect(get_child(i), Rect2(item_size * Vector2(factor, pos_in_layer), item_size))
			# vertical directions
			Direction.UP, Direction.DOWN:
				var item_size := Vector2(size.x / float(num_nodes_in_layer), size.y / float(_num_layers))
				fit_child_in_rect(get_child(i), Rect2(item_size * Vector2(pos_in_layer, factor), item_size))

		if pos_in_layer == num_nodes_in_layer - 1:
			layer += 1
			pos_in_layer = 0
			num_nodes_in_layer /= 2
		else:
			pos_in_layer += 1


func _draw() -> void:
	if not draw_enabled:
		return

	var num_nodes_in_first_layer := 2 ** _biggest_included_power_of_two

	for i in range(_num_children):
		var successor_id := num_nodes_in_first_layer + i / 2
		if successor_id >= _num_children:
			continue

		var node_a = get_child(i)
		var node_b = get_child(num_nodes_in_first_layer + i / 2)

		if not (node_a.visible and node_b.visible):
			continue

		var start = node_a.position + 0.5 * node_a.size
		var end = node_b.position + 0.5 * node_b.size

		var points : Array[Vector2] = []
		if direction % 2 == 0: # vertical direction
			var intersection_point := Vector2(start.x, end.y)
			points = [
				start.move_toward(intersection_point, draw_shortened + 0.5 * node_a.size.y),
				intersection_point,
				end.move_toward(intersection_point, draw_shortened + 0.5 * node_b.size.x)
			]
		else:
			var intersection_point := Vector2(end.x, start.y)
			points = [
				start.move_toward(intersection_point, draw_shortened + 0.5 * node_a.size.x),
				intersection_point,
				end.move_toward(intersection_point, draw_shortened + 0.5 * node_b.size.y)
			]

		draw_polyline(
			points,
			draw_color,
			draw_width,
			draw_antialiased
		)
