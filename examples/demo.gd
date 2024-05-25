extends Control


@onready var CONTAINER := $VBox/PyramidContainer

@onready var node_set_1 := CONTAINER.get_children()
var node_set_2 := []

var active_node_set := 1

func _ready() -> void:
	for i in range(15):
		var color_rect := ColorRect.new()
		color_rect.color = Color(randf(), randf(), randf())
		node_set_2.append(color_rect)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				CONTAINER.direction = wrapi(
					CONTAINER.direction + 1, 0, CONTAINER.Direction.size()
				)
			KEY_SPACE:
				for child in CONTAINER.get_children():
					CONTAINER.remove_child(child)
				active_node_set = wrapi(active_node_set + 1, 1, 3)
				for node in get("node_set_%d" % active_node_set):
					CONTAINER.add_child(node)
