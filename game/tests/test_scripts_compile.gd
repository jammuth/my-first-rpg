extends TestCase

## Most game scripts (UI, scenes) have no tests of their own, so a typo in one would otherwise only
## show up when the game runs. Loading every script compiles it; the runner fails the test on any
## error that raises.

const ROOTS: Array[String] = ["res://scripts", "res://tools"]


func test_every_game_script_compiles() -> void:
	var paths: Array[String] = []
	for dir in ROOTS:
		_collect(dir, paths)
	assert_true(paths.size() > 40, "found only %d scripts" % paths.size())
	for path in paths:
		var script := load(path) as GDScript
		assert_true(script != null and script.can_instantiate(), "%s compiles" % path)


func _collect(dir: String, out: Array[String]) -> void:
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			out.append(dir.path_join(file))
	for sub in DirAccess.get_directories_at(dir):
		_collect(dir.path_join(sub), out)
