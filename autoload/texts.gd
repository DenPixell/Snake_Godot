class_name Texts
extends RefCounted
## Надписи меню на английском и русском. Экран Game Boy всегда на английском,
## как у настоящей приставки.

const LANGUAGES: Array[String] = ["en", "ru"]

const RU := {
	"PLAY": "ИГРАТЬ",
	"SETTINGS": "НАСТРОЙКИ",
	"EXIT": "ВЫХОД",
	"PAUSE": "ПАУЗА",
	"CONTINUE": "ПРОДОЛЖИТЬ",
	"MAIN MENU": "ГЛАВНОЕ МЕНЮ",
	"BACK": "НАЗАД",
	"MUSIC": "МУЗЫКА",
	"EFFECTS": "ЭФФЕКТЫ",
	"LANGUAGE": "ЯЗЫК",
	"RESOLUTION": "РАЗРЕШЕНИЕ",
	"FULLSCREEN": "ПОЛНЫЙ ЭКРАН",
	"VSYNC": "ВЕРТ. СИНХР.",
	"CONTROLS": "УПРАВЛЕНИЕ",
	"ON": "ВКЛ",
	"OFF": "ВЫКЛ",
	"EN": "EN",
	"RU": "RU",
	"UP": "ВВЕРХ",
	"DOWN": "ВНИЗ",
	"LEFT": "ВЛЕВО",
	"RIGHT": "ВПРАВО",
	"BUTTON A": "КНОПКА A",
	"BUTTON B": "КНОПКА B",
	"START": "START",
	"MENU": "МЕНЮ",
	"PRESS KEY": "НАЖМИТЕ...",
	"RESET KEYS": "СБРОС КЛАВИШ",
	"TUTORIAL": "ОБУЧЕНИЕ",
	"ITEMS": "ПРЕДМЕТЫ",
	"DOT": "ТОЧКА",
	"BIG APPLE": "БОЛЬШОЕ ЯБЛОКО",
	"ROTTEN APPLE": "ГНИЛОЕ ЯБЛОКО",
	"ROTTEN BANANA": "ГНИЛОЙ БАНАН",
	"LIGHTNING": "МОЛНИЯ",
	"BRICK": "КИРПИЧ",
	"+1 LENGTH, +1 SCORE": "+1 К ДЛИНЕ, +1 К СЧЕТУ",
	"+%d-%d LENGTH, +1 SCORE": "+%d-%d К ДЛИНЕ, +1 К СЧЕТУ",
	"CONTROLS INVERTED FOR %d SEC": "УПРАВЛЕНИЕ НАОБОРОТ %d СЕК",
	"BLIND FOR %d SEC: YOU SEE ONLY NEAR THE HEAD": "СЛЕПОТА %d СЕК: ВИДНО ТОЛЬКО ОКОЛО ГОЛОВЫ",
	"+%d SPEED FOR %d SEC": "+%d К СКОРОСТИ НА %d СЕК",
	"PUTS A WALL ON THE FIELD FOREVER": "СТАВИТ СТЕНУ НА ПОЛЕ НАВСЕГДА",
	"ICONS ON THE LEFT OF THE SCREEN SHOW TIME LEFT": "ЗНАЧКИ СЛЕВА НА ЭКРАНЕ ПОКАЗЫВАЮТ, СКОЛЬКО ОСТАЛОСЬ",
	"THE SAME EFFECT AGAIN ADDS %d SEC": "ПОВТОРНЫЙ ЭФФЕКТ ДОБАВЛЯЕТ %d СЕК",
	"EASY: NO TRAPS": "EASY: БЕЗ ЛОВУШЕК",
	"NORMAL: %d SAFE DOTS AFTER A TRAP": "NORMAL: %d ОБЫЧНЫЕ ТОЧКИ ПОСЛЕ ЛОВУШКИ",
	"HARD: TRAPS AT ANY TIME": "HARD: ЛОВУШКИ В ЛЮБОЙ МОМЕНТ",
	"FOR BETTER IMMERSION": "ДЛЯ ЛУЧШЕГО ПОГРУЖЕНИЯ",
	"PLAY WITH HEADPHONES": "ИГРАЙТЕ В НАУШНИКАХ",
	"LMB": "ЛКМ",
	"RMB": "ПКМ",
	"MMB": "СКМ",
}


static func translate(text: String, language: String) -> String:
	if language == "ru":
		return RU.get(text, text)
	return text
