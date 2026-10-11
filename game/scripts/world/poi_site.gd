class_name PoiSite
extends Node3D

## A POI compound built from its planned layout. Pieces get the weathering shader; solid pieces get
## box colliders (cut down to the remaining height on ruined buildings).

var data: PoiData


static func create(poi: PoiData, pieces: PoiPieceLibrary) -> PoiSite:
	var site := PoiSite.new()
	site.data = poi
	site.name = "Poi_" + poi.id
	site.position = poi.position
	var body := StaticBody3D.new()
	site.add_child(body)
	for item: Dictionary in poi.layout:
		var info := pieces.get_info(item.key)
		var piece: Dictionary = PoiCatalog.piece(item.key)
		var pivot := Node3D.new()
		var local: Vector2 = item.position - poi.position_2d()
		pivot.position = Vector3(local.x, item.y, local.y)
		pivot.rotation.y = item.yaw
		site.add_child(pivot)
		var model: Node3D = info.scene.instantiate()
		model.scale = Vector3.ONE * piece.scale
		# Centre the model's footprint on the slot regardless of where its source pivot was.
		var centre: Vector3 = info.aabb.get_center() * piece.scale
		model.position = Vector3(-centre.x, 0.0, -centre.z)
		pivot.add_child(model)
		var height: float = info.aabb.size.y * piece.scale
		var base_y: float = poi.position.y + item.y
		var ruin_height: float = 100000.0 if item.ruin <= 0.0 else base_y + height * item.ruin
		for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			pieces.apply_weathering(mi)
			mi.set_instance_shader_parameter("base_y", base_y)
			mi.set_instance_shader_parameter("ruin_height", ruin_height)
		if piece.solid:
			var kept: float = height * (item.ruin if item.ruin > 0.0 else 1.0)
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			var size: Vector3 = info.aabb.size * piece.scale
			box.size = Vector3(size.x, kept, size.z)
			shape.shape = box
			shape.transform = Transform3D(Basis(Vector3.UP, item.yaw),
				pivot.position + Vector3(0, kept * 0.5 + info.aabb.position.y * piece.scale, 0))
			body.add_child(shape)
	return site
