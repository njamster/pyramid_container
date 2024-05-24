@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type("PyramidContainer", "Container", preload("pyramid_container.gd"), preload("icon.svg"))


func _exit_tree() -> void:
	remove_custom_type("PyramidContainer")
