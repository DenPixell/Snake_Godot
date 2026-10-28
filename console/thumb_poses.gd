class_name ThumbPoses
extends Resource
## Сдвиги больших пальцев от позы из сцены hold_pose.tscn при нажатии каждой кнопки.
## Каждая запись: {"base": градусы первой фаланги, "tip": градусы двух следующих}.
## Файл создаёт инструмент tools/thumb_poses.gd — руками его править не нужно.

@export var left := {}
@export var right := {}
