extends MarginContainer

const DUMMY_ELEMENT := preload("res://examples/dummy_element.tscn")


func _ready() -> void:
	# add child nodes, one by one
	while $PyramidContainer.get_child_count() < 15:
		await(get_tree().create_timer(0.4).timeout)
		var dummy := DUMMY_ELEMENT.instantiate()
		$PyramidContainer.add_child(dummy)
		dummy.get_node("Label").text = "Node %d" % $PyramidContainer.get_child_count()
		dummy.custom_minimum_size = dummy.get_node("Label").get_combined_minimum_size()

	await(get_tree().create_timer(0.5).timeout)   # pause

	# gradually increase the v_separation
	while $PyramidContainer.v_separation < 10:
		await(get_tree().create_timer(0.1).timeout)
		$PyramidContainer.v_separation += 2

	# gradually increase the h_separation
	while $PyramidContainer.h_separation < 20:
		await(get_tree().create_timer(0.05).timeout)
		$PyramidContainer.h_separation += 2

	await(get_tree().create_timer(0.5).timeout)   # pause

	# demonstrate horizontal size flags
	$PyramidContainer.size_flags_horizontal = SIZE_SHRINK_CENTER
	await(get_tree().create_timer(0.5).timeout)
	$PyramidContainer.size_flags_horizontal = SIZE_SHRINK_END
	await(get_tree().create_timer(0.5).timeout)
	$PyramidContainer.size_flags_horizontal = SIZE_FILL

	await(get_tree().create_timer(0.5).timeout)   # pause

	# demonstrate vertical size flags
	$PyramidContainer.size_flags_vertical = SIZE_SHRINK_CENTER
	await(get_tree().create_timer(0.5).timeout)
	$PyramidContainer.size_flags_vertical = SIZE_SHRINK_END
	await(get_tree().create_timer(0.5).timeout)
	$PyramidContainer.size_flags_vertical = SIZE_FILL

	await(get_tree().create_timer(1.0).timeout)   # pause

	# demonstrate container directions
	$PyramidContainer.direction = $PyramidContainer.Direction.LEFT
	await(get_tree().create_timer(1.0).timeout)
	$PyramidContainer.direction = $PyramidContainer.Direction.DOWN
	await(get_tree().create_timer(1.0).timeout)
	$PyramidContainer.direction = $PyramidContainer.Direction.RIGHT

	await(get_tree().create_timer(1.0).timeout)   # pause

	# gradually hide the visuals for the assigned area
	for child in $PyramidContainer.get_children():
		child.texture = null
		child.size_flags_horizontal = SIZE_SHRINK_CENTER
		child.size_flags_vertical = SIZE_SHRINK_CENTER
		await(get_tree().create_timer(0.1).timeout)

	await(get_tree().create_timer(0.3).timeout)   # pause

	# demonstrate the automatic connection drawing
	$PyramidContainer.draw_enabled = true

	# gradually increase the line width
	while $PyramidContainer.draw_width < 5:
		await(get_tree().create_timer(0.2).timeout)
		$PyramidContainer.draw_width += 1

	# gradually increase the line shortening
	while $PyramidContainer.draw_shortened < 20:
		await(get_tree().create_timer(0.2).timeout)
		$PyramidContainer.draw_shortened += 5

	await(get_tree().create_timer(0.2).timeout)   # pause

	# demonstrate different line colors
	$PyramidContainer.draw_color = Color("#BF616A")
	await(get_tree().create_timer(0.5).timeout)
	$PyramidContainer.draw_color = Color("#A3BE8C")
	await(get_tree().create_timer(0.5).timeout)
	$PyramidContainer.draw_color = Color("#81A1C1")

	await(get_tree().create_timer(3.0).timeout)   # pause

	# restart the demo
	get_tree().reload_current_scene()

