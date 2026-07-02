# Backend: Agent Core Templates (#114)

## API — TemplateEngine

### render(template: string, variables: object): string
- `[var]` — простая подстановка
- `[nested.key]` — вложенные ключи
- `{% if var %}...{% endif %}` — условный блок
- `{% each array as item %}...[item.prop]...{% endeach %}` — цикл

## API — TemplateLoader

### load(name: string): Promise<string>
### loadAll(): Promise<object>
### exists(name: string): Promise<boolean>

## API — TemplateRegistry

### init(): Promise<void>
### render(name: string, variables: object): Promise<string>

## Agent Contract

```js
class Agent {
  setTemplateRegistry(registry)
  renderTemplate(name, vars)  // вызывает registry.render()
  execute(context)             // использует renderTemplate()
}
```
