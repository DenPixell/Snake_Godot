#!/bin/sh
# Запуск тестов логики. Падает, если хоть один тест упал или в скриптах есть ошибка.
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
cd "$(dirname "$0")/.." || exit 1
"$GODOT" --headless --path . --import >/dev/null 2>&1
OUTPUT=$("$GODOT" --headless --path . -s tests/run_tests.gd 2>&1)
STATUS=$?
echo "$OUTPUT" | grep -E "FAIL|ERROR|Тестов"
if [ $STATUS -ne 0 ] || echo "$OUTPUT" | grep -q "ERROR"; then
	exit 1
fi
