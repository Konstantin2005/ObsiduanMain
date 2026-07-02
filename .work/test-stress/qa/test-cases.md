# Test Cases (17)

## Core CRUD
| TC | Описание | Ожидаемый результат |
|---|---|---|
| TC-01 | Создать задачу с title и description | 201, task created |
| TC-02 | Создать задачу без title | 400, validation error |
| TC-03 | Создать задачу с title > 200 символов | 400 |
| TC-04 | Получить список всех задач | 200, array |
| TC-05 | Получить задачу по ID | 200, task object |
| TC-06 | Получить несуществующую задачу | 404 |
| TC-07 | Обновить title задачи | 200, version incremented |
| TC-08 | Удалить задачу (soft) | 200, status = archived |

## Conflict Resolution
| TC | Описание | Ожидаемый результат |
|---|---|---|
| TC-09 | PUT с правильной version | 200 success |
| TC-10 | PUT с устаревшей version | 409 conflict |
| TC-11 | POST /merge после конфликта | 200, resolved |
| TC-12 | Merge с некорректными данными | 400 |

## Sync
| TC | Описание | Ожидаемый результат |
|---|---|---|
| TC-13 | GET /sync с timestamp | 200, changes array |
| TC-14 | GET /sync без timestamp | 200, все задачи |
| TC-15 | POST /sync/push с корректными actions | 200, applied count |
| TC-16 | POST /sync/push с конфликтующими actions | 200, conflicts array |

## Edge Cases (из edge-cases.md)
| TC | Описание | Ожидаемый результат |
|---|---|---|
| TC-17 | Два пользователя PUT одновременно (race condition) | Один 200, второй 409 |
