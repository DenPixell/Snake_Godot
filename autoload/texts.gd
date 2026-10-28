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
	"LMB": "ЛКМ",
	"RMB": "ПКМ",
	"MMB": "СКМ",
}


static func translate(text: String, language: String) -> String:
	if language == "ru":
		return RU.get(text, text)
	return text
