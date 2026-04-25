@tool
extends Node

const vrm_top_level = preload("./vrm_toplevel.gd")
const vrm_secondary = preload("./vrm_secondary.gd")
const vrm_meta_class = preload("./vrm_meta.gd")

func _ready():
	if Engine.is_editor_hint():
		# In editor, detect when scenes are opened or nodes are added
		get_tree().node_added.connect(_on_node_added_editor)
	else:
		# At runtime, process existing nodes and watch for new ones
		_call_deferred_check(get_tree().root)
		get_tree().node_added.connect(_on_node_added_runtime)

func _on_node_added_editor(node: Node):
	# Only process nodes that are part of the edited scene
	if node.scene_file_path.is_empty():
		return
	_call_deferred_check(node)

func _on_node_added_runtime(node: Node):
	_call_deferred_check(node)

func _call_deferred_check(node: Node):
	# Use call_deferred to ensure the node is fully initialized
	check_node.call_deferred(node)

func check_node(node: Node):
	if not node is Node3D:
		return
	
	# Check if this is a VRM root by structure
	var skeleton = node.find_child("*Skeleton*", true, false)
	var is_vrm = skeleton != null and skeleton.find_bone("Hips") != -1 and skeleton.find_bone("Head") != -1
	if is_vrm and node.get_script() != vrm_top_level:
		print("VRMRuntimeDetector: fixing VRMTopLevel on ", node.name)
		node.set_script(vrm_top_level)
		# Restore vrm_meta if available
		if node.has_meta("vrm_meta"):
			var meta = node.get_meta("vrm_meta")
			if meta is vrm_meta_class:
				node.set("vrm_meta", meta)
				print("VRMRuntimeDetector: restored vrm_meta")
		
		# Restore secondary node by name
		var secondary = node.get_node_or_null("secondary")
		if secondary and secondary.get_script() != vrm_secondary:
			print("VRMRuntimeDetector: fixing vrm_secondary on ", secondary.name)
			secondary.set_script(vrm_secondary)
			if secondary.has_meta("vrm_secondary_skeleton"):
				secondary.set("skeleton", secondary.get_meta("vrm_secondary_skeleton"))
			if secondary.has_meta("vrm_secondary_spring_bones"):
				secondary.set("spring_bones", secondary.get_meta("vrm_secondary_spring_bones"))
			print("VRMRuntimeDetector: vrm_secondary restored")
	
	# Also check children recursively
	for child in node.get_children():
		check_node(child)
