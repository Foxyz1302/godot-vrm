@tool
extends EditorScenePostImportPlugin

const vrm_top_level = preload("./vrm_toplevel.gd")

func _get_import_options(path: String):
	if path.is_empty() or path.get_extension().to_lower() == "vrm":
		add_import_option_advanced(TYPE_INT, "vrm/head_hiding_method", 0, PROPERTY_HINT_ENUM,
			"ThirdPersonOnly,FirstPersonOnly,FirstWithShadow,Layers,LayersWithShadow,IgnoreHeadHiding")
		add_import_option_advanced(TYPE_INT, "vrm/only_if_head_hiding_uses_layers/first_person_layers", 2, PROPERTY_HINT_LAYERS_3D_RENDER)
		add_import_option_advanced(TYPE_INT, "vrm/only_if_head_hiding_uses_layers/third_person_layers", 4, PROPERTY_HINT_LAYERS_3D_RENDER)

func _post_process(scene: Node):
	# In Godot 4.7+, the editor's import pipeline strips scripts set during
	# GLTFDocumentExtension._import_post due to script property being marked
	# as PROPERTY_USAGE_INTERNAL. We detect VRM scenes by structure and restore
	# scripts regardless of metadata (which may also be stripped in some cases).
	
	var skeleton = scene.find_child("*Skeleton*", true, false)
	if not skeleton:
		return
	
	# Detection: VRM imports have skeletons with humanoid bone names
	if skeleton.find_bone("Hips") == -1 or skeleton.find_bone("Head") == -1:
		return
	
	# Always mark as VRM import
	scene.set_meta("vrm_is_imported", true)
	
	# Restore root VRMTopLevel script
	if scene.get_script() != vrm_top_level:
		scene.set_script(vrm_top_level)
	
	# Restore vrm_meta if available in metadata
	if scene.has_meta("vrm_meta"):
		var meta = scene.get_meta("vrm_meta")
		scene.set("vrm_meta", meta)
	
	# Restore secondary node script - any child named "secondary" with no script
	var secondary = scene.get_node_or_null("secondary")
	if secondary and secondary.get_script() == null:
		var vrm_secondary_script = preload("./vrm_secondary.gd")
		secondary.set_script(vrm_secondary_script)
		# Try to restore properties from metadata if available
		if secondary.has_meta("vrm_secondary_skeleton"):
			secondary.set("skeleton", secondary.get_meta("vrm_secondary_skeleton"))
		if secondary.has_meta("vrm_secondary_spring_bones"):
			secondary.set("spring_bones", secondary.get_meta("vrm_secondary_spring_bones"))
