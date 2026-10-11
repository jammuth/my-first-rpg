class_name CharacterBuilder
extends RefCounted

## Assembles a CharacterOptions entry into a scene: base model, hidden parts, grafted parts and the
## shared animations. Used by both the menu preview and the in-game explorer.

const TINT_SHADER := preload("res://shaders/cloth_tint.gdshader")


static func build(id: String) -> Node3D:
	var option: Dictionary = CharacterOptions.OPTIONS[id]
	var root: Node3D = (load(option.base) as PackedScene).instantiate()
	root.name = "Character"
	var skeleton := skeleton_of(root)
	for mesh_name: String in option.hide:
		# Freed now, not queued, so the built scene is final when this returns.
		skeleton.get_node(mesh_name).free()
	var donors := {}
	for graft: Dictionary in option.grafts:
		if not donors.has(graft.from):
			donors[graft.from] = (load(graft.from) as PackedScene).instantiate()
		graft_mesh(donors[graft.from], graft.mesh, skeleton, graft.get("scale", 1.0), graft.get("offset", Vector3.ZERO))
	for donor: Node in donors.values():
		donor.free()
	for mesh_name in CharacterOptions.SAND_GEAR:
		var mesh := skeleton.get_node_or_null(mesh_name) as MeshInstance3D
		if mesh != null:
			tint(mesh, CharacterOptions.KHAKI)
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	player.add_animation_library("", ExplorerAnimations.library())
	root.add_child(player)
	return root


static func skeleton_of(root: Node) -> Skeleton3D:
	return root.get_node("Rig_Medium/Skeleton3D")


## Copies a skinned mesh onto another skeleton. Skin binds are re-pointed by bone name because the
## two rigs list their bones in different orders. scale/offset adjust the fit in each bone's space.
static func graft_mesh(donor: Node, mesh_name: String, skeleton: Skeleton3D, scale := 1.0,
		offset := Vector3.ZERO) -> MeshInstance3D:
	var donor_skeleton := skeleton_of(donor)
	var mesh := (donor_skeleton.get_node(mesh_name) as MeshInstance3D).duplicate() as MeshInstance3D
	var skin: Skin = mesh.skin.duplicate()
	var adjust := Transform3D(Basis().scaled(Vector3.ONE * scale), offset)
	for i in skin.get_bind_count():
		var bone_name := String(skin.get_bind_name(i))
		if bone_name.is_empty():
			bone_name = donor_skeleton.get_bone_name(skin.get_bind_bone(i))
		skin.set_bind_bone(i, skeleton.find_bone(bone_name))
		skin.set_bind_pose(i, adjust * skin.get_bind_pose(i))
	mesh.skin = skin
	skeleton.add_child(mesh)
	mesh.skeleton = NodePath("..")
	return mesh


static func tint(mesh: MeshInstance3D, color: Color) -> void:
	var source := mesh.get_active_material(0) as StandardMaterial3D
	var material := ShaderMaterial.new()
	material.shader = TINT_SHADER
	material.set_shader_parameter("albedo_texture", source.albedo_texture)
	material.set_shader_parameter("tint", color)
	mesh.material_override = material
