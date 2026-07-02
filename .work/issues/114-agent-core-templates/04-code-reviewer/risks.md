# Risks — Agent Core Templates (#114)

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Template syntax collision | Low | Medium | `[var]` синтаксис не конфликтует с Markdown |
| Each regex fails on complex nested | Medium | Low | Single level each — достаточно для задач |
| Missing variable shown as `[var]` | Low | Low | Очевидно для разработчика |
| Template directory moved | High | Low | Путь резолвится относительно `__dirname` |
