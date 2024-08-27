extends Control

# TODO this isn't seeming to do anything so doesn't actually seem needed

func ready() -> void:
	get_viewport().connect("gui_focus_changed", self, "_on_focus_changed")

func _on_focus_changed(control:Control) -> void:
	if control != null:
		print("Focus Changed:", control.name)
