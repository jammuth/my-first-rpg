extends TestCase

const ExplorerScene := preload("res://scenes/explorer.tscn")


func test_explorer_is_blocked_by_walls_and_can_back_away() -> void:
	var root := (Engine.get_main_loop() as SceneTree).root
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(8, 4, 1)
	shape.shape = box
	wall.add_child(shape)
	wall.position = Vector3(0, 2, -5)
	root.add_child(wall)
	var explorer: Explorer = ExplorerScene.instantiate()
	explorer.set_physics_process(false)
	root.add_child(explorer)
	explorer.global_position = Vector3(0, 0.05, 0)
	assert_true(explorer.test_move(explorer.global_transform, Vector3(0, 0, -5)), "walked through the wall")
	assert_false(explorer.test_move(explorer.global_transform, Vector3(0, 0, -3)), "blocked before reaching it")
	assert_false(explorer.test_move(explorer.global_transform, Vector3(0, 0, 3)), "blocked walking away")
	explorer.free()
	wall.free()
