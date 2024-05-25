@tool
@icon("pyramid_container.svg")
class_name PyramidContainer extends Container
## A container that arranges its child controls in the shape of a pyramid.

enum Direction {
	UP,
	RIGHT,
	DOWN,
	LEFT
}
@export var direction := Direction.RIGHT:
	set(value):
		direction = value
		if is_inside_tree():
			propagate_notification(NOTIFICATION_SORT_CHILDREN)
			queue_redraw()


@export_group("Line Drawing", "draw_")
@export var draw_enabled := false:
	set(value):
		draw_enabled = value
		if is_inside_tree():
			queue_redraw()

@export_range(1, 10, 1, "or_greater", "suffix:px") var draw_line_width := 3.0:
	set(value):
		draw_line_width = value
		if is_inside_tree():
			queue_redraw()

@export_range(0, 50, 1, "or_greater", "suffix:px") var draw_shortened := 20:
	set(value):
		draw_shortened = value
		if is_inside_tree():
			queue_redraw()

@export var draw_antialiased := true:
	set(value):
		draw_antialiased = value
		if is_inside_tree():
			queue_redraw()

@export var draw_color := Color.WHITE:
	set(value):
		draw_color = value
		if is_inside_tree():
			queue_redraw()


# for internal use only!
var _num_layers : int
var _num_children : int
var _biggest_included_power_of_two : int


func _ready() -> void:
	if draw_enabled:
		await get_tree().process_frame
		queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
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
					fit_child_in_rect(get_child(i), Rect2(
						Vector2(size.x / _num_layers * factor, size.y / num_nodes_in_layer * pos_in_layer),
						Vector2(size.x / _num_layers, size.y / num_nodes_in_layer)
					))
				# vertical directions
				Direction.UP, Direction.DOWN:
					fit_child_in_rect(get_child(i), Rect2(
						Vector2(size.x / num_nodes_in_layer * pos_in_layer, size.y / _num_layers * factor),
						Vector2(size.x / num_nodes_in_layer, size.y / _num_layers)
					))

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

		var start = node_a.global_position + 0.5 * node_a.size
		var end = node_b.global_position + 0.5 * node_b.size
		var intersection_point := Vector2(end.x, start.y)
		if direction == Direction.UP or direction == Direction.DOWN:
			intersection_point = Vector2(start.x, end.y)

		draw_polyline(
			[
				start.move_toward(intersection_point, draw_shortened),
				intersection_point,
				end.move_toward(intersection_point, draw_shortened)
			],
			draw_color,
			draw_line_width,
			draw_antialiased
		)
