class_name Difficulty
extends RefCounted
## Правила трёх уровней сложности.

enum Level { EASY, NORMAL, HARD }

## Шанс, что следующий объект окажется усложнением.
const COMPLICATION_CHANCE := 0.5
## Сколько обычных точек гарантировано после усложнения на Normal.
const NORMAL_PROTECTION := 3


static func has_complications(level: Level) -> bool:
	return level != Level.EASY


## Сколько точек подряд выпадет после подобранного усложнения.
static func protection(level: Level) -> int:
	return NORMAL_PROTECTION if level == Level.NORMAL else 0


## На Normal новое усложнение не появляется, пока действует эффект.
static func waits_for_effects(level: Level) -> bool:
	return level == Level.NORMAL


static func has_leaderboard(level: Level) -> bool:
	return level != Level.EASY
