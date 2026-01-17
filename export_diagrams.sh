#!/bin/bash
# Скрипт для экспорта всех PlantUML диаграмм из _puml в SVG
# Автоматически заменяет существующие SVG файлы

# Переход в директорию с исходными файлами
cd "$(dirname "$0")/_puml" || exit 1

# Проверка наличия PlantUML
if ! command -v plantuml &> /dev/null; then
    echo "Ошибка: PlantUML не установлен."
    echo "Установите PlantUML: brew install plantuml"
    exit 1
fi

# Создание целевой директории, если её нет
mkdir -p ../docs/assets/diagrams

# Удаление всех существующих SVG файлов из целевой директории
echo "Очистка целевой директории от старых SVG файлов..."
rm -f ../docs/assets/diagrams/*.svg
if [ $? -eq 0 ]; then
    echo "✓ Старые SVG файлы удалены"
else
    echo "⚠ Не удалось удалить некоторые старые файлы (возможно, директория пуста)"
fi
echo ""

# Экспорт всех файлов *.puml в SVG
echo "Экспорт всех диаграмм *.puml в SVG..."
echo "Целевая директория: ../docs/assets/diagrams/"
echo ""

count=0
errors=0

for file in *.puml; do
    if [ -f "$file" ]; then
        count=$((count + 1))
        svg_name=$(basename "$file" .puml).svg
        echo "[$count] Обработка: $file"
        
        # Экспорт в SVG (существующие файлы автоматически перезаписываются)
        plantuml -tsvg "$file" -o ../docs/assets/diagrams
        
        if [ $? -eq 0 ]; then
            echo "    ✓ Успешно: $file -> $svg_name"
        else
            echo "    ✗ Ошибка при обработке: $file"
            errors=$((errors + 1))
        fi
    fi
done

echo ""
if [ $errors -eq 0 ]; then
    echo "✓ Экспорт завершён успешно! Обработано файлов: $count"
    echo "✓ SVG файлы находятся в: docs/assets/diagrams/"
else
    echo "⚠ Экспорт завершён с ошибками. Успешно: $((count - errors)), Ошибок: $errors"
fi

echo ""
echo "Нажмите Enter для выхода..."
read
