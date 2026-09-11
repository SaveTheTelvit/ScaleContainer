@tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("ScaleContainer", "Container", preload("scale_container.gd"), preload("ScaleContainer.svg"))

func _exit_tree():
	remove_custom_type("ScaleContainer")
