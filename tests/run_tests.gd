extends SceneTree
## Запуск всех тестов без окна:
## Godot --headless --path . -s tests/run_tests.gd

const TEST_FILES: Array[String] = [
	"res://tests/test_board.gd",
	"res://tests/test_effects.gd",
	"res://tests/test_spawner.gd",
	"res://tests/test_snake_game.gd",
]


func _initialize() -> void:
	var passed := 0
	var failed := 0
	for path in TEST_FILES:
		var script: GDScript = load(path)
		for method in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			var test: TestCase = script.new()
			test.call(name)
			if test.failures.is_empty():
				passed += 1
			else:
				failed += 1
				for failure in test.failures:
					printerr("FAIL %s::%s — %s" % [path.get_file(), name, failure])
	print("Тестов пройдено: %d, упало: %d" % [passed, failed])
	quit(1 if failed > 0 else 0)
