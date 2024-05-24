extends Control

var players := ["P1", "P4"]

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed:
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		label.text = players[randi() % 2]
		$PyramidContainer.add_child(label)
