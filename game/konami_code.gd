class_name KonamiCode
extends RefCounted
## Код Конами: вверх, вверх, вниз, вниз, влево, вправо, влево, вправо, B, A.
## Помним последние нажатия и сравниваем их с кодом.

const SEQUENCE: Array[String] = [
	"gb_up", "gb_up", "gb_down", "gb_down", "gb_left", "gb_right", "gb_left", "gb_right", "gb_b", "gb_a",
]

var _recent: Array[String] = []


## Новое нажатие. true — код только что введён полностью.
func feed(action: String) -> bool:
	_recent.append(action)
	if _recent.size() > SEQUENCE.size():
		_recent.pop_front()
	if _recent == SEQUENCE:
		_recent.clear()
		return true
	return false
