# Edge Cases — Agent Core Templates (#114)

## TemplateEngine Edge Cases
1. **Пустая строка** — `render('', {})` → `''`
2. **Нет переменных** — `render('[missing]', {})` → `'[missing]'` (остаётся as-is)
3. **Цикл с пустым массивом** — `render('{% each items as i %}[i]{% endeach %}', {items:[]})` → `''`
4. **Цикл с null** — `render('{% each items as i %}[i]{% endeach %}', {})` → `''`
5. **Множественные циклы** — 2+ each в одном шаблоне
6. **Вложенные each** — не поддерживается (single level)
7. **Спецсимволы в значениях** — `[title]` с `<>"'&`

## Loader Edge Cases
8. **Файл не найден** — выбрасывает Error с понятным сообщением
9. **Пустая папка шаблонов** — loadAll() → `{}`
10. **Кэширование** — повторный load() возвращает кэш

## Pipeline Edge Cases
11. **Issue без title** — `slug` = пустая строка
12. **Issue без id** — отображается как 'N/A'
13. **Ошибка TemplateRegistry** — pipeline пробрасывает ошибку наверх
