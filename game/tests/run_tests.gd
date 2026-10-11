extends SceneTree

## Headless runner: godot --headless --path game -s res://tests/run_tests.gd [-- filter]

const TEST_DIR := "res://tests"


# GDScript has no exceptions: a runtime error just aborts the test function, so count engine errors
# raised during each test and treat any as a failure.
class ErrorCounter extends Logger:
	var count := 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type != ERROR_TYPE_WARNING:
			count += 1

	func _log_message(_message: String, _error: bool) -> void:
		pass


func _initialize() -> void:
	var filter := ""
	var user_args := OS.get_cmdline_user_args()
	if not user_args.is_empty():
		filter = user_args[0]
	var counter := ErrorCounter.new()
	OS.add_logger(counter)
	var passed := 0
	var failed := 0
	var files := DirAccess.get_files_at(TEST_DIR)
	files.sort()
	for file in files:
		if not (file.begins_with("test_") and file.ends_with(".gd")) or file == "test_case.gd":
			continue
		var script: GDScript = load(TEST_DIR.path_join(file))
		if script == null or not script.can_instantiate():
			failed += 1
			print("  FAIL ", file.get_basename(), " (script failed to load, see log above)")
			continue
		for method in script.get_script_method_list():
			var name: String = method.name
			if not name.begins_with("test_"):
				continue
			var label := "%s::%s" % [file.get_basename(), name]
			if filter != "" and not label.contains(filter):
				continue
			var case: TestCase = script.new()
			var errors_before := counter.count
			case.call(name)
			var problems := case.failures.duplicate()
			if counter.count > errors_before:
				problems.append("engine/script error raised during test (see log above)")
			elif case.assertions == 0:
				problems.append("test made no assertions")
			if problems.is_empty():
				passed += 1
				print("  PASS ", label)
			else:
				failed += 1
				print("  FAIL ", label)
				for p in problems:
					print("       - ", p)
	OS.remove_logger(counter)
	print("\n%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 or passed == 0 else 0)
