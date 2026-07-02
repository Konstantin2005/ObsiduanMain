# Components — Templates

## Template Syntax

### Variables
```md
[title]           → простые
[user.name]       → вложенные
```

### Conditionals
```md
{% if show %}
  visible content
{% endif %}
```

### Loops
```md
{% each items as item %}
  [item.name] — [item.value]
{% endeach %}
```

## Reusable Patterns
- Все шаблоны используют `[id]`, `[title]`, `[slug]` как base variables
- `backend-api` и `frontend-ui` используют `{% each %}` для динамических данных
- `review` использует `{% if %}` для условных секций безопасности
- `context` использует `{% if %}` для дефолтного состояния vs кастомного
