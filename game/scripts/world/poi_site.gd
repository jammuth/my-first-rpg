class_name PoiSite
extends Node3D

var data: PoiData


static func create(poi: PoiData, model: PackedScene, plaza_material: Material) -> PoiSite:
	var site := PoiSite.new()
	site.data = poi
	site.name = "Poi_" + poi.id
	site.position = poi.position

	var plaza := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = poi.plaza_radius
	disc.bottom_radius = poi.plaza_radius
	disc.height = 0.2
	disc.radial_segments = 32
	disc.rings = 1
	disc.material = plaza_material
	plaza.mesh = disc
	plaza.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	site.add_child(plaza)

	var pivot := Node3D.new()
	pivot.rotation.y = poi.yaw
	site.add_child(pivot)
	var building: Node3D = model.instantiate()
	building.scale = Vector3.ONE * poi.model_scale
	pivot.add_child(building)

	var aabb := _model_aabb(building)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = aabb.size * poi.model_scale
	shape.shape = box
	shape.position = aabb.get_center() * poi.model_scale
	body.add_child(shape)
	pivot.add_child(body)
	return site


static func _model_aabb(root: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		var xform := Transform3D.IDENTITY
		var n: Node = mi
		while n != root:
			xform = (n as Node3D).transform * xform
			n = n.get_parent()
		var box := xform * mi.mesh.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result
