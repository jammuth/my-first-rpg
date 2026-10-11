class_name PropLibrary
extends RefCounted

## Main-thread cache of single meshes pulled out of prop model scenes, for use in MultiMeshes.

var _entries := {}


## Returns {mesh: Mesh, transform: Transform3D} with the mesh's offset inside its source scene.
func get_entry(path: String) -> Dictionary:
	if _entries.has(path):
		return _entries[path]
	var root: Node3D = load(path).instantiate()
	var mi: MeshInstance3D = root.find_children("*", "MeshInstance3D", true, false)[0]
	var xform := Transform3D.IDENTITY
	var n: Node = mi
	while n != root:
		xform = (n as Node3D).transform * xform
		n = n.get_parent()
	var entry := {"mesh": mi.mesh, "transform": xform}
	root.free()
	_entries[path] = entry
	return entry
