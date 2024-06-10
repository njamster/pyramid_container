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
		queue_sort()


@export_group("Line Drawing", "draw_")
@export var draw_enabled := false:
	set(value):
		draw_enabled = value
		queue_redraw()

@export_range(1, 10, 1, "or_greater", "suffix:px") var draw_width := 3.0:
	set(value):
		draw_width = value
		queue_redraw()

@export_range(0, 50, 1, "or_greater", "suffix:px") var draw_shortened := 10:
	set(value):
		draw_shortened = value
		queue_redraw()

@export var draw_color := Color.WHITE:
	set(value):
		draw_color = value
		queue_redraw()

@export var draw_antialiased := true:
	set(value):
		draw_antialiased = value
		queue_redraw()


# internal variables
var _layer_width : Array[float] = [ 0.0 ]
var _node_heights : Array[float] = []


func _highest_included_power_of_two(n: int) -> int:
	n |= n >> 1
	n |= n >> 2
	n |= n >> 4
	n |= n >> 8
	n |= n >> 16
	return n ^ (n >> 1)


func _get_minimum_size() -> Vector2:
	var minimum_size := Vector2.ZERO

	# only count child nodes that are currently visible
	var sortable_children : Array[Control] = []
	for child in get_children():
		if child is Control and child.visible:
			sortable_children.append(child)

	var sortable_child_count := sortable_children.size()

	# if there are none, we're done here: there is no minimum size!
	if sortable_child_count == 0:
		return minimum_size

	# reset internal helper variables
	_node_heights = []
	_layer_width = [ 0.0 ]

	var layer := 0
	var pos_in_layer := 0
	var max_nodes_in_layer := _highest_included_power_of_two(sortable_child_count)

	for i in sortable_child_count:
		var child = sortable_children[i]

		var child_size := child.get_combined_minimum_size()
		if layer > 0:
			# child should be at least as high as its predecessors from the previous layer combined
			var predecessor_1_height := _node_heights[i - 2 * max_nodes_in_layer]
			var predecessor_2_height := _node_heights[i - 2 * max_nodes_in_layer + 1]
			child_size.y = max(child_size.y, predecessor_1_height + predecessor_2_height)

		_layer_width[layer] = max(_layer_width[layer], child_size.x)

		_node_heights.append(child_size.y)
		# if child has no successor in the next layer...
		if i + max_nodes_in_layer - ceil(0.5 * pos_in_layer) >= sortable_child_count:
			# ...its size is part of the minimum size of the container
			minimum_size.y += child_size.y

		if pos_in_layer == max_nodes_in_layer -1 or i == sortable_child_count - 1:
			minimum_size.x += _layer_width[layer]

		if pos_in_layer == max_nodes_in_layer -1:
			layer += 1
			pos_in_layer = 0
			max_nodes_in_layer /= 2
			if i < sortable_child_count - 1:
				_layer_width.append(0.0)
		else:
			pos_in_layer += 1

	return minimum_size


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_resort()


func _resort() -> void:
	# only count child nodes that are currently visible
	var sortable_children : Array[Control] = []
	for child in get_children():
		if child is Control and child.visible:
			sortable_children.append(child)

	var sortable_child_count := sortable_children.size()

	# if there are none, we're done here: there is nothing to sort!
	if sortable_child_count == 0:
		return

	var stretch_space := size - _get_minimum_size()

	var layer := 0
	var offset := Vector2.ZERO
	var pos_in_layer := 0
	var max_nodes_in_layer := _highest_included_power_of_two(sortable_child_count)

	for i in sortable_child_count:
		var child := sortable_children[i]

		var width = _layer_width[layer]
		if size_flags_horizontal & SIZE_FILL:
			width += stretch_space.x / _layer_width.size()

		var height = _node_heights[i]
		if size_flags_vertical & SIZE_FILL:
			height += stretch_space.y / max_nodes_in_layer

		fit_child_in_rect(child, Rect2(offset.x, offset.y, width, height))

		if pos_in_layer == max_nodes_in_layer - 1  or i == sortable_child_count - 1:
			offset = Vector2(offset.x + width, 0)
			layer += 1
			pos_in_layer = 0
			max_nodes_in_layer /= 2
		else:
			offset.y += height
			pos_in_layer += 1

	queue_redraw()


func _get_allowed_size_flags_horizontal() -> PackedInt32Array:
	return [
		SIZE_FILL,
		SIZE_SHRINK_BEGIN,
		SIZE_SHRINK_CENTER,
		SIZE_SHRINK_END
	]


func _get_allowed_size_flags_vertical() -> PackedInt32Array:
	return [
		SIZE_FILL,
		SIZE_SHRINK_BEGIN,
		SIZE_SHRINK_CENTER,
		SIZE_SHRINK_END
	]


func _draw() -> void:
	if not draw_enabled:
		return

	var sortable_children : Array[Control] = []
	for child in get_children():
		if child is Control and child.visible:
			sortable_children.append(child)

	var sortable_child_count := sortable_children.size()

	# if there are none, we're done here: there is nothing to draw
	if sortable_child_count == 0:
		return

	var num_nodes_in_first_layer := _highest_included_power_of_two(sortable_child_count)

	for i in range(sortable_child_count):
		var successor_id := num_nodes_in_first_layer + i / 2
		if successor_id >= sortable_child_count:
			continue

		var node_a = sortable_children[i]
		var node_b = sortable_children[num_nodes_in_first_layer + i / 2]

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
