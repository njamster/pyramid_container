@tool
@icon("pyramid_container.svg")
class_name PyramidContainer extends Container
## A container that arranges its child controls in the shape of a pyramid.
##
## A container that arranges its child controls in the shape of a pyramid. That is, the
## [code]biggest included power of two[/code] nodes will form the base layer, with the amount of
## nodes on each subsequent layer being halfed, until all nodes have been assigned.

enum Direction {
	## [b]PyramidContainer[/b] will face the negative Y-axis. Nodes inside each layer will be added
	## from left to right, new layers will be added at the top.
	UP    = 0,
	## [b]PyramidContainer[/b] will face the positive X-axis. Nodes inside each layer will be added
	## from top to bottom, new layers will be added at the right.
	RIGHT = 1,
	## [b]PyramidContainer[/b] will face the positive Y-axis. Nodes inside each layer will be added
	## from left to right, new layers will be added at the bottom.
	DOWN  = 2,
	## [b]PyramidContainer[/b] will face the negative X-axis. Nodes inside each layer will be added
	## from top to bottom, new layers will be added at the left.
	LEFT  = 3
}

## Direction that the [b]PyramidContainer[/b] is facing. See [enum Direction] for options.
@export var direction := Direction.UP:
	set(value):
		if direction != value:
			var was_vertical := _is_vertical()
			direction = value
			if _is_vertical() != was_vertical:
				var swap_value := h_separation
				h_separation = v_separation
				v_separation = swap_value
			update_minimum_size()
			queue_sort()

## Amount of horizontal pixels added between child nodes of the [b]PyramidContainer[/b].
## [br][br]
## [b]Note:[/b] The value of this variable will be automatically swapped with the value of
## [member v_separation] when the container's [member direction] changes from a vertical to a
## horizontal value and vice versa.
@export_range(0.0, 0.0, 1.0, "or_greater", "suffix:px") var h_separation := 0.0:
	set(value):
		if h_separation != value:
			h_separation = value
			update_minimum_size()
			queue_sort()

## Amount of vertical pixels added between child nodes of the [b]PyramidContainer[/b].
## [br][br]
## [b]Note:[/b] The value of this variable will be automatically swapped with the value of
## [member h_separation] when the container's [member direction] changes from a vertical to a
## horizontal value and vice versa.
@export_range(0.0, 0.0, 1.0, "or_greater", "suffix:px") var v_separation := 0.0:
	set(value):
		if v_separation != value:
			v_separation = value
			update_minimum_size()
			queue_sort()

## If [code]true[/code], the [b]PyramidContainer[/b] won't assign space to [i]hidden[/i] child
## nodes. Therefore, when a childs's visibility changes, other children will change their place
## and/or size. If you use this container for drawing a tournament bracket (i.e.
## [member draw_enabled] is [code]true[/code]), you might want to disable this in order to be able
## to unveil nodes step-by-step without affecting the overall layout.
@export var visible_children_only := true:
	set(value):
		if visible_children_only != value:
			visible_children_only = value
			update_minimum_size()
			queue_sort()


@export_group("Line Drawing", "draw_")

## If [code]true[/code], the [b]PyramidContainer[/b] will be rendered as a tournament bracket by
## automatically drawing connection lines from each succesive pair of nodes on layer [code]x[/code]
## to their successor node on layer [code]x+1[/code].
## [br][br]
## [b]Note:[/b] If any of the involved nodes is currently hidden, their connecting line will
## [i]not[/i] be drawn!
@export var draw_enabled := false:
	set(value):
		if draw_enabled != value:
			draw_enabled = value
			queue_redraw()

## The width of the connection lines in pixels.
## [br][br]
## [i]Only takes effect if [member draw_enabled] is [code]true[/code].[/i]
@export_range(1.0, 10.0, 1.0, "or_greater", "suffix:px") var draw_width := 3.0:
	set(value):
		if draw_width != value:
			draw_width = value
			queue_redraw()

## The length in pixels each connection line will get shortened by on both ends.
## [br][br]
## [i]Only takes effect if [member draw_enabled] is [code]true[/code].[/i]
@export_range(0.0, 50.0, 1.0, "or_greater", "suffix:px") var draw_shortened := 10.0:
	set(value):
		if draw_shortened != value:
			draw_shortened = value
			queue_redraw()

## The color of the connection lines.
## [br][br]
## [i]Only takes effect if [member draw_enabled] is [code]true[/code].[/i]
@export var draw_color := Color.WHITE:
	set(value):
		if draw_color != value:
			draw_color = value
			queue_redraw()

## If [code]true[/code], the connection lines will be antialiased.
## [br][br]
## [i]Only takes effect if [member draw_enabled] is [code]true[/code].[/i]
@export var draw_antialiased := false:
	set(value):
		if draw_antialiased != value:
			draw_antialiased = value
			queue_redraw()


#region INTERNAL VARIABLES
# Holds the exact width of each layer.
# Computed in [method _get_minimum_size], assigned in [method _resort].
var _layer_width : Array[float] = [ 0.0 ]
# Holds the exact height of each child node.
# Computed in [method _get_minimum_size], assigned in [method _resort].
var _node_heights : Array[float] = []
#endregion


# Returns the minimum size of the [b]PyramidContainer[/b], considering the minimum size of all its
# child nodes. Alternative to [member Control.custom_minimum_size] for controlling minimum size via
# code. The actual minimum  size will be the max value of these two (in each axis separately).
func _get_minimum_size() -> Vector2:
	var minimum_size := Vector2.ZERO

	# only consider child nodes that are Control nodes and currently visible
	var sortable_children : Array[Control] = []
	for child in get_children():
		if child is Control:
			if child.visible or not visible_children_only:
				sortable_children.append(child)
	var sortable_child_count := sortable_children.size()

	# if none fulfill those criteria, we're done here: minimum size is (0, 0)!
	if sortable_child_count == 0:
		return minimum_size

	var num_nodes_in_first_layer : int = _highest_included_power_of_two(sortable_child_count)

	# reset internal variables to their default values
	_node_heights = []
	_layer_width = [ 0.0 ]

	#region FORWARD LOOP
	# initialize loop variables (will be re-used in BACKWARDS LOOP later)
	var layer := 0
	var position_in_layer := 0
	var max_nodes_in_layer : int = num_nodes_in_first_layer

	for i in sortable_child_count:
		var child : Control = sortable_children[i]

		var child_size : Vector2 = child.get_combined_minimum_size()
		if layer > 0:
			# child should be at least as high as its predecessors from the previous layer combined
			var predecessor_1_index : int = i - 2 * max_nodes_in_layer + position_in_layer
			var predecessor_1_height : float = _node_heights[predecessor_1_index]
			var predecessor_2_height : float = _node_heights[predecessor_1_index + 1]
			if _is_vertical():
				child_size.x = max(child_size.x, predecessor_1_height + predecessor_2_height)
			else:
				child_size.y = max(child_size.y, predecessor_1_height + predecessor_2_height)

		if _is_vertical():
			_layer_width[layer] = max(_layer_width[layer], child_size.y)
			_node_heights.append(child_size.x)
		else:
			_layer_width[layer] = max(_layer_width[layer], child_size.x)
			_node_heights.append(child_size.y)

		# if child has no successor in the next layer...
		if num_nodes_in_first_layer + i / 2 >= sortable_child_count:
			# ... its size is part of the minimum size of the container
			if _is_vertical():
				minimum_size.x += child_size.x
			else:
				minimum_size.y += child_size.y

		# if child is the last child in the current layer or overall...
		if position_in_layer == max_nodes_in_layer - 1 or i == sortable_child_count - 1:
			# ... its size is part of the minimum size of the container
			if _is_vertical():
				minimum_size.y += _layer_width[layer]
			else:
				minimum_size.x += _layer_width[layer]

		# unless child is the last child overall...
		if i < sortable_child_count - 1:
			# ... if it is the last child on the current layer...
			if position_in_layer == max_nodes_in_layer - 1:
				# ... advance to next layer
				layer += 1
				position_in_layer = 0
				max_nodes_in_layer /= 2
				if _is_vertical():
					minimum_size.y += v_separation
				else:
					minimum_size.x += h_separation
				_layer_width.append(0.0)
			else:
				# ... advance to the next position in the current layer
				position_in_layer += 1
	#endregion

	# add missing separation pixels to the minimum_size
	if _is_vertical():
		minimum_size.x += (min(num_nodes_in_first_layer, sortable_child_count) - 1) * h_separation
	else:
		minimum_size.y += (min(num_nodes_in_first_layer, sortable_child_count) - 1) * v_separation

	#region BACKWARDS LOOP
	# re-uses the final values of the loop variables from the FORWARD LOOP region!

	# for all children except those on the first layer...
	for i in range(sortable_child_count-1, num_nodes_in_first_layer - 1, -1):
		var own_size : float = _node_heights[i]

		var predecessor_1_index : int = i - 2 * max_nodes_in_layer + position_in_layer
		var predecessor_1_height : float = _node_heights[predecessor_1_index]
		var predecessor_2_height : float = _node_heights[predecessor_1_index + 1]

		# ... split the difference in height between the child and the combined height of its two
		# predecessors evenly and add the resulting height to each predecessor
		# NOTE: stretch_space can't become negative, since we already completed the FORWARD LOOP,
		# which guarantees that every child is a least as big as their predecessors combined!
		var stretch_space := own_size - predecessor_1_height - predecessor_2_height
		_node_heights[predecessor_1_index] += stretch_space / 2
		_node_heights[predecessor_1_index + 1] += stretch_space / 2

		# if the current node is the first in the current layer...
		if position_in_layer == 0:
			# ... go back to the previous layer
			max_nodes_in_layer *= 2
			position_in_layer = max_nodes_in_layer - 1
		else:
			# ... go back to the previous position in the current layer
			position_in_layer -= 1
	#endregion

	return minimum_size


# Called when the [b]PyramidContainer[/b] receives a notification, which can be identified in
# [param what] by comparing it with a constant. Calls [member _resort] after receiving
# [constant Object.NOTIFICATION_SORT_CHILDREN].
# [br][br]
# See also [member Object.notification].
func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_resort()


# Assigns a [code]position[/code] and [code]size[/code] to each child node of the
# [b]PyramidContainer[/b]. This [i]does[/i] include hidden nodes, unless
# [member visible_children_only] is set to [code]true[/code].
# [br][br]
# Corresponds to the [constant Object.NOTIFICATION_SORT_CHILDREN] notification in
# [method _notification].
func _resort() -> void:
	# only consider child nodes that are Control nodes and currently visible
	var sortable_children : Array[Control] = []
	for child in get_children():
		if child is Control:
			if child.visible or not visible_children_only:
				sortable_children.append(child)
	var sortable_child_count := sortable_children.size()

	# if none fulfill those criteria, we're done here: there is nothing to sort!
	if sortable_child_count == 0:
		return

	# get the difference between the containers current and minimum size
	var stretch_space : Vector2 = size - _get_minimum_size()

	#region FORWARD LOOP
	# initialize loop variables
	var layer := 0
	var offset := Vector2.ZERO   # starting position: top-left corner of the container
	if direction == Direction.UP:
		offset.y = size.y   # starting position: bottom left corner of the container
	elif direction == Direction.LEFT:
		offset.x = size.x   # starting position: top right corner of the container
	var position_in_layer := 0
	var max_nodes_in_layer : int = _highest_included_power_of_two(sortable_child_count)

	for i in sortable_child_count:
		var child : Control = sortable_children[i]

		var width : float
		var height : float
		if _is_vertical():
			# dimensions are flipped, i.e. _node_heights contains the width instead of the height
			width = _node_heights[i]
			# if child is set to fill the available space horizontally...
			if size_flags_horizontal & SIZE_FILL:
				# ... stretch it's minimum size accordingly
				width += stretch_space.x / max_nodes_in_layer

			# dimensions are flipped, i.e. _layer_width contains the height instead of the width
			height = _layer_width[layer]
			# if child is set to fill the available space vertically...
			if size_flags_vertical & SIZE_FILL:
				# ... stretch it's minimum size accordingly
				height += stretch_space.y / _layer_width.size()

			# add separation pixels between layers
			width += ((2 ** layer) - 1) * h_separation
		else:
			width = _layer_width[layer]
			# if child is set to fill the available space horizontally...
			if size_flags_horizontal & SIZE_FILL:
				# ... stretch it's minimum size accordingly
					width += stretch_space.x / _layer_width.size()
#
			height = _node_heights[i]
			# if child is set to fill the available space vertically...
			if size_flags_vertical & SIZE_FILL:
				# ... stretch it's minimum size accordingly
				height += stretch_space.y / max_nodes_in_layer

			# add separation pixels between layers
			height += ((2 ** layer) - 1) * v_separation

		#region FIT CHILD IN
		if direction == Direction.UP:
			# account for the node's height by adjusting the Y-offset accordingly
			fit_child_in_rect(child, Rect2(offset.x, offset.y - height, width, height))
		elif direction == Direction.LEFT:
			# account for the node's width by adjusting the X-offset accordingly
			fit_child_in_rect(child, Rect2(offset.x - width, offset.y, width, height))
		else:
			fit_child_in_rect(child, Rect2(offset.x, offset.y, width, height))
		#endregion

		# if child is the last child in the current layer or overall...
		if position_in_layer == max_nodes_in_layer - 1  or i == sortable_child_count - 1:
			# ... advance to next layer
			layer += 1
			position_in_layer = 0
			max_nodes_in_layer /= 2
			match direction:
				Direction.UP:
					offset = Vector2(0, offset.y - height - v_separation)
				Direction.RIGHT:
					offset = Vector2(offset.x + width + h_separation, 0)
				Direction.DOWN:
					offset = Vector2(0, offset.y + height + v_separation)
				Direction.LEFT:
					offset = Vector2(offset.x - width - h_separation, 0)
		else:
			# add separation pixels between nodes on the same layer...
			if _is_vertical():
				offset.x += width + h_separation
			else:
				offset.y += height + v_separation
			# ... and advance to the next position in the current layer
			position_in_layer += 1
	#endregion

	queue_redraw() # children may have moved or resized, so we need to re-draw the connection lines


# Returns a list of allowed horizontal [enum Control.SizeFlags] for children of the
# [b]PyramidContainer[/b]. This doesn't technically prevent the usages of any other size flags, it
# only limits the options available to the user in the Inspector dock.
# [constant Control.SIZE_EXPAND] is excluded here, since children [i]always[/i] expand.
func _get_allowed_size_flags_horizontal() -> PackedInt32Array:
	return [
		SIZE_FILL,
		SIZE_SHRINK_BEGIN,
		SIZE_SHRINK_CENTER,
		SIZE_SHRINK_END
	]


# Returns a list of allowed vertical [enum Control.SizeFlags] for children of the
# [b]PyramidContainer[/b]. This doesn't technically prevent the usages of any other size flags, it
# only limits the options available to the user in the Inspector dock.
# [constant Control.SIZE_EXPAND] is excluded here, since children [i]always[/i] expand.
func _get_allowed_size_flags_vertical() -> PackedInt32Array:
	return [
		SIZE_FILL,
		SIZE_SHRINK_BEGIN,
		SIZE_SHRINK_CENTER,
		SIZE_SHRINK_END
	]


# Called when [b]PyramidContainer[/b] has been requested to redraw (after
# [method CanvasItem.queue_redraw] is called, either manually or by the engine). When
# [member draw_enabled] is [code]true[/code], it will draw connection lines from each succesive
# pair of nodes on layer [code]x[/code] to their successor node on layer [code]x+1[/code].
# [br][br]
# Corresponds to the [constant CanvasItem.NOTIFICATION_DRAW] notification in
# [method _notification].
func _draw() -> void:
	if not draw_enabled:
		return

	# only consider child nodes that are Control nodes and currently visible
	var sortable_children : Array[Control] = []
	for child in get_children():
		if child is Control:
			if child.visible or not visible_children_only:
				sortable_children.append(child)
	var sortable_child_count := sortable_children.size()

	# if not at least 3 fulfill those criteria, we're done here: there is nothing to draw!
	if sortable_child_count < 3:
		return

	var num_nodes_in_first_layer : int = _highest_included_power_of_two(sortable_child_count)

	for i in range(sortable_child_count):
		var successor_id : int = num_nodes_in_first_layer + i / 2
		if successor_id >= sortable_child_count:
			return

		var node_a : Control = sortable_children[i]
		var node_b : Control = sortable_children[successor_id]

		if not (node_a.visible and node_b.visible):
			continue

		var connection_line_points : Array[Vector2] = []

		var start_point : Vector2 = node_a.position + 0.5 * node_a.size # center of node_a
		var end_point : Vector2 = node_b.position + 0.5 * node_b.size # center of node_a

		if _is_vertical():
			# if the end_point is on a node that shrinks to the beginning or end of the available
			# space, and the start_point corresponds to that by being the upper or lower member of
			# a bracket inside its layer...
			if (node_b.size_flags_horizontal == SIZE_SHRINK_BEGIN and i % 2 == 0) or \
			(node_b.size_flags_horizontal == SIZE_SHRINK_END and i % 2 == 1):
				# ... directly connect start_point and end_point. This can result in a diagonal line
				# in some cases, but avoids a bunch of other possible weird corner cases.
				connection_line_points = [
					start_point.move_toward(end_point, draw_shortened + 0.5 * node_a.size.x),
					end_point.move_toward(start_point, draw_shortened + 0.5 * node_b.size.x)
				]
			else:
				# ... connect the start_point to the end_point via an intersection_point, which
				# guarantees two connected straight lines connection start_point and end_point.
				var intersection_point := Vector2(start_point.x, end_point.y)
				connection_line_points = [
					start_point.move_toward(intersection_point, draw_shortened + 0.5 * node_a.size.y),
					intersection_point,
					end_point.move_toward(intersection_point, draw_shortened + 0.5 * node_b.size.x)
				]
		else:
			# if the end_point is on a node that shrinks to the beginning or end of the available
			# space, and the start_point corresponds to that by being the upper or lower member of
			# a bracket inside its layer...
			if (node_b.size_flags_vertical == SIZE_SHRINK_BEGIN and i % 2 == 0) or \
			(node_b.size_flags_vertical == SIZE_SHRINK_END and i % 2 == 1):
				# ... directly connect start_point and end_point. This can result in a diagonal line
				# in some cases, but avoids a bunch of other possible weird corner cases.
				connection_line_points = [
					start_point.move_toward(end_point, draw_shortened + 0.5 * node_a.size.x),
					end_point.move_toward(start_point, draw_shortened + 0.5 * node_b.size.x)
				]
			else:
				# ... connect the start_point to the end_point via an intersection_point, which
				# guarantees two connected straight lines connection start_point and end_point.
				var intersection_point := Vector2(end_point.x, start_point.y)
				connection_line_points = [
					start_point.move_toward(intersection_point, draw_shortened + 0.5 * node_a.size.x),
					intersection_point,
					end_point.move_toward(intersection_point, draw_shortened + 0.5 * node_b.size.y)
				]

		draw_polyline(
			connection_line_points,
			draw_color,
			draw_width,
			draw_antialiased
		)


#region helper functions
# Returns the highest power of two that is below (or equal to) an integer [param n].
func _highest_included_power_of_two(n: int) -> int:
	# flip all bits in n to 1
	n |= n >> 1
	n |= n >> 2
	n |= n >> 4
	n |= n >> 8
	n |= n >> 16
	# get rid of the highest bit in n, then substract that from n to only leave the highest bit set
	# since every bit represents a power of 2, this bit is the highest power of two included in n!
	return n ^ (n >> 1)


# Returns [code]true[/code], if the current [member direction] is [constant UP] or [constant DOWN].
func _is_vertical() -> bool:
	return direction == Direction.UP or direction == Direction.DOWN
#endregion
