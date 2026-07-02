# Test Cases — Agent Core Templates (#114)

## TemplateEngine

| TC | Name | Input | Expected | Status |
|----|------|-------|----------|--------|
| 1 | Simple variable | `render('Hello [name]', {name:'World'})` | `'Hello World!'` | ✅ |
| 2 | Conditional true | `render('{% if x %}y{% endif %}', {x:true})` | `'y'` | ✅ |
| 3 | Conditional false | `render('{% if x %}y{% endif %}', {x:false})` | `''` | ✅ |
| 4 | Each loop | `render('{% each items as i %}- [i]\n{% endeach %}', {items:['a','b']})` | `'- a\n- b\n'` | ✅ |
| 5 | Nested keys | `render('[user.name]', {user:{name:'Alice'}})` | `'Alice'` | ✅ |

## TemplateLoader

| TC | Name | Input | Expected | Status |
|----|------|-------|----------|--------|
| 6 | Load existing | `loader.load('plan')` | string with `[title]` | ✅ |
| 7 | Load nonexistent | `loader.load('nope')` | throws Error | ✅ |
| 8 | exists() true | `loader.exists('plan')` | `true` | ✅ |
| 9 | exists() false | `loader.exists('nope')` | `false` | ✅ |
| 10 | loadAll counts | `loader.loadAll()` | 8 templates | ✅ |

## Integration

| TC | Name | Input | Expected | Status |
|----|------|-------|----------|--------|
| 11 | Registry render | `registry.render('plan', {id:1, title:'T', slug:'t'})` | contains 'T', '#1' | ✅ |
| 12 | Pipeline + Architect | orchestrator.run(mockIssue) | plan.md has title + id | ✅ |
| 13 | Pipeline + Reviewer | orchestrator.run(mockIssue) | review.md has 'Approve' | ✅ |
