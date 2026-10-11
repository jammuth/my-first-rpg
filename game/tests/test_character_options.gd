extends TestCase


func test_order_covers_every_option_and_default() -> void:
	var ids: Array = CharacterOptions.OPTIONS.keys()
	ids.sort()
	var ordered := CharacterOptions.ORDER.duplicate()
	ordered.sort()
	assert_eq(ordered, ids)
	assert_true(CharacterOptions.is_valid(CharacterOptions.DEFAULT))
	assert_false(CharacterOptions.is_valid("nobody"))


func test_cycle_wraps_both_ways() -> void:
	var first: String = CharacterOptions.ORDER[0]
	var last: String = CharacterOptions.ORDER[-1]
	assert_eq(CharacterOptions.cycle(last, 1), first)
	assert_eq(CharacterOptions.cycle(first, -1), last)
	assert_eq(CharacterOptions.cycle(first, 1), CharacterOptions.ORDER[1])


func test_every_option_builds_as_specified() -> void:
	for id: String in CharacterOptions.ORDER:
		var option: Dictionary = CharacterOptions.OPTIONS[id]
		var character := CharacterBuilder.build(id)
		var skeleton := CharacterBuilder.skeleton_of(character)
		for hidden: String in option.hide:
			assert_true(skeleton.get_node_or_null(hidden) == null, "%s still has %s" % [id, hidden])
		for graft: Dictionary in option.grafts:
			var mesh := skeleton.get_node_or_null(graft.mesh) as MeshInstance3D
			assert_not_null(mesh, "%s missing graft %s" % [id, graft.mesh])
			if mesh != null:
				for i in mesh.skin.get_bind_count():
					assert_true(mesh.skin.get_bind_bone(i) >= 0, "%s: %s bind %d has no bone" % [id, graft.mesh, i])
		for gear in CharacterOptions.SAND_GEAR:
			var mesh := skeleton.get_node_or_null(gear) as MeshInstance3D
			assert_not_null(mesh, "%s has no %s" % [id, gear])
			if mesh != null:
				assert_true(mesh.material_override is ShaderMaterial, "%s: %s not tinted" % [id, gear])
		character.free()


func test_animations_loop_and_drive_every_skeleton() -> void:
	var library := ExplorerAnimations.library()
	for anim_name in ExplorerAnimations.LOOPING:
		assert_eq(library.get_animation(anim_name).loop_mode, Animation.LOOP_LINEAR, anim_name)
	for anim_name in [ExplorerAnimations.INTERACT, ExplorerAnimations.PICK_UP]:
		assert_true(library.has_animation(anim_name), anim_name)
	var walk := library.get_animation(ExplorerAnimations.WALK)
	for id: String in CharacterOptions.ORDER:
		var character := CharacterBuilder.build(id)
		var skeleton := CharacterBuilder.skeleton_of(character)
		for t in walk.get_track_count():
			var path := walk.track_get_path(t)
			assert_eq(String(path.get_concatenated_names()), "Rig_Medium/Skeleton3D", "%s track %d node" % [id, t])
			assert_true(skeleton.find_bone(String(path.get_concatenated_subnames())) >= 0,
				"%s lacks bone %s" % [id, path.get_concatenated_subnames()])
		var player := character.get_node("AnimationPlayer") as AnimationPlayer
		assert_true(player.has_animation(ExplorerAnimations.IDLE), id)
		character.free()
