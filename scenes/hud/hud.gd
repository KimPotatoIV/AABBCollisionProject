extends CanvasLayer

##################################################
var count_label_node: Label
var f_p_s_label_node: Label

##################################################
func _ready() -> void:
	count_label_node = $MarginContainer/VBoxContainer/CountLabel
	f_p_s_label_node = $MarginContainer/VBoxContainer/FPSLabel

##################################################
func _process(delta: float) -> void:
	count_label_node.text = "Obj Count: " + str(GameManager.get_object_count())
	f_p_s_label_node.text = "FPS: " + str(Engine.get_frames_per_second())
