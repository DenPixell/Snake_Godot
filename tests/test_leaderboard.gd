extends TestCase


func test_zero_score_does_not_qualify() -> void:
	check(not Leaderboard.new().qualifies(0), "ноль не записываем")


func test_sorted_best_first() -> void:
	var board := Leaderboard.new()
	board.add("AAA", 5)
	board.add("BBB", 20)
	board.add("CCC", 10)
	check_eq(board.entries.map(func(e: Dictionary) -> String: return e["name"]),
			["BBB", "CCC", "AAA"], "порядок")


func test_keeps_only_ten() -> void:
	var board := Leaderboard.new()
	for i in 15:
		board.add("P%02d" % i, i + 1)
	check_eq(board.entries.size(), Leaderboard.SIZE, "десять записей")
	check_eq(board.entries.back()["score"], 6, "худший оставшийся")
	check(not board.qualifies(6), "равный последнему не вытесняет его")
	check_eq(board.add("NEW", 3), -1, "слабый результат не попадает")


func test_equal_score_goes_below() -> void:
	var board := Leaderboard.new()
	board.add("OLD", 10)
	check_eq(board.add("NEW", 10), 1, "второе место")


func test_name_trimmed_to_three_letters() -> void:
	var board := Leaderboard.new()
	board.add("abcd", 1)
	check_eq(board.entries[0]["name"], "ABC", "три заглавные буквы")


func test_load_skips_broken_entries() -> void:
	var data := [{"name": "AAA", "score": 3}, {"name": 5}, "мусор", {"name": "BBB", "score": 7}]
	var board := Leaderboard.from_array(data)
	check_eq(board.entries.size(), 2, "две целые записи")
	check_eq(board.entries[0]["name"], "BBB", "отсортировано")
	check_eq(Leaderboard.from_array(null).entries.size(), 0, "пустой файл")
