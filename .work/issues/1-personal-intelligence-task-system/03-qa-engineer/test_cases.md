# PITS — QA Test Cases

## Memory Core

### TC-MEM-01: Сохранение записи
- Input: Entry(source="test", raw_text="Hello")
- Expected: entry.id > 0
- Status: PASS (test_save_entry)

### TC-MEM-02: Получение записи по ID
- Input: entry_id после сохранения
- Expected: fetched.raw_text == "Test entry"
- Status: PASS (test_get_entry)

### TC-MEM-03: Получение всех записей (10)
- Input: 20 entries
- Expected: len(entries) == 10
- Status: PASS (test_get_all_entries)

### TC-MEM-04: Сохранение памяти
- Input: Memory(entry_id, content, type, confidence)
- Expected: memory.id > 0
- Status: PASS (test_save_memory)

### TC-MEM-05: Поиск по типу памяти
- Input: 5 memories of type "task"
- Expected: filter returns exactly 5
- Status: PASS (test_get_memories_by_type)

### TC-MEM-06: Поиск похожих (cosine similarity)
- Input: identical vectors
- Expected: similarity ≈ 1.0
- Status: PASS (test_cosine_similarity)

### TC-MEM-07: Поиск ортогональных
- Input: orthogonal vectors
- Expected: similarity ≈ 0.0
- Status: PASS (test_similarity_orthogonal)

### TC-MEM-08: Сохранение задачи
- Input: Task with title, confidence, status
- Expected: task.id > 0
- Status: PASS (test_save_task)

### TC-MEM-09: Обновление статуса задачи
- Input: suggested -> approved
- Expected: task found by approved status
- Status: PASS (test_update_task_status)

### TC-MEM-10: Фильтрация задач по статусу
- Input: 3 suggested tasks
- Expected: returned exactly 3
- Status: PASS (test_get_tasks_by_status)

### TC-MEM-11: Сохранение обратной связи
- Input: Feedback(decision="accepted")
- Expected: feedback.id > 0
- Status: PASS (test_save_feedback)

### TC-MEM-12: Получение фидбека по задаче
- Input: 2 feedbacks for same task
- Expected: len >= 2
- Status: PASS (test_get_feedback_for_task)

## Ingestion

### TC-ING-01: Загрузка текста
- Input: "Hello world"
- Expected: source="manual", text="Hello world"
- Status: PASS (test_load_text)

### TC-ING-02: Загрузка файла .txt
- Input: temp .txt file
- Expected: content == "Test diary entry"
- Status: PASS (test_load_file)

### TC-ING-03: Загрузка неподдерживаемого формата
- Input: .pdf file
- Expected: None
- Status: PASS (test_load_file_unsupported)

### TC-ING-04: Загрузка несуществующего файла
- Input: nonexistent.txt
- Expected: None
- Status: PASS (test_load_missing_file)

### TC-ING-05: Разделение записей
- Input: "First\n---\nSecond"
- Expected: list of 2 entries
- Status: PASS (test_split_entries)

### TC-ING-06: Извлечение даты
- Input: "2024-01-15 event"
- Expected: date extracted
- Status: PASS (test_extract_date)

### TC-ING-07: Извлечение тегов
- Input: "#fix #car"
- Expected: tags=["fix", "car"]
- Status: PASS (test_extract_tags)

### TC-ING-08: Очистка Markdown ссылок
- Input: "[link](url)"
- Expected: URL removed, text preserved
- Status: PASS (test_clean_markdown_links)

### TC-ING-09: Очистка заголовков
- Input: "## Header"
- Expected: "##" removed
- Status: PASS (test_clean_markdown_headers)

### TC-ING-10: Очистка URL
- Input: URL in text
- Expected: replaced with [URL]
- Status: PASS (test_clean_urls)

### TC-ING-11: Очистка пустого текста
- Input: ""
- Expected: ""
- Status: PASS (test_clean_empty)

## Analyzer

### TC-ANL-01: Парсинг валидного JSON
- Input: '{"items": [{"type":"task","title":"Fix car","confidence":85,...}]}'
- Expected: 1 Suggestion with type="task", confidence=85
- Status: PASS (test_parse_valid_json)

### TC-ANL-02: Парсинг пустого ответа
- Input: '{"items": []}'
- Expected: 0 suggestions
- Status: PASS (test_parse_no_items)

### TC-ANL-03: Парсинг мусора
- Input: "not json"
- Expected: 0 suggestions
- Status: PASS (test_parse_malformed_json)

### TC-ANL-04: JSON в тексте
- Input: text with embedded JSON
- Expected: JSON extracted and parsed
- Status: PASS (test_parse_json_in_text)

### TC-ANL-05: Множественные элементы
- Input: 2 items in array
- Expected: 2 suggestions
- Status: PASS (test_parse_multiple_items)

### TC-ANL-06: Валидация suggestion
- Input: valid Suggestion
- Expected: _is_valid == True
- Status: PASS (test_valid_suggestion)

### TC-ANL-07: Валидация неверного типа
- Input: type="invalid"
- Expected: _is_valid == False
- Status: PASS (test_invalid_type)

### TC-ANL-08: Валидация confidence > 100
- Input: confidence=150
- Expected: _is_valid == False
- Status: PASS (test_invalid_confidence)

### TC-ANL-09: Валидация короткого title
- Input: title="AB"
- Expected: _is_valid == False
- Status: PASS (test_short_title)

### TC-ANL-10: Actionable task
- Input: type="task", confidence=85
- Expected: is_actionable == True
- Status: PASS (test_is_actionable)

### TC-ANL-11: Не actionability (низкий confidence)
- Input: confidence=20
- Expected: is_actionable == False
- Status: PASS (test_not_actionable_low_confidence)

### TC-ANL-12: Не actionability (vague words)
- Input: "maybe someday fix car"
- Expected: is_actionable == False
- Status: PASS (test_not_actionable_vague)

## Decision Engine

### TC-DEC-01: Auto threshold (≥85)
- Input: confidence=90
- Expected: status="automatic"
- Status: PASS (test_auto_threshold)

### TC-DEC-02: Suggest threshold (50-85)
- Input: confidence=65
- Expected: status="suggested"
- Status: PASS (test_suggest_threshold)

### TC-DEC-03: Memory only (<50)
- Input: confidence=30
- Expected: status="memory"
- Status: PASS (test_memory_threshold)

### TC-DEC-04: Custom thresholds
- Input: auto=90, suggest=60
- Expected: stored correctly
- Status: PASS (test_custom_thresholds)

### TC-DEC-05: Dedup — exact match
- Input: "Fix the car" then "Fix the car"
- Expected: is_duplicate == True
- Status: PASS (test_exact_duplicate)

### TC-DEC-06: Dedup — similar
- Input: "Fix the car" then "fix car"
- Expected: is_duplicate == True
- Status: PASS (test_similar_duplicate)

### TC-DEC-07: Dedup — no duplicate
- Input: "Fix the car" then "Buy groceries"
- Expected: is_duplicate == False
- Status: PASS (test_no_duplicate)

### TC-DEC-08: Dedup — empty DB
- Input: any title
- Expected: is_duplicate == False
- Status: PASS (test_empty_db)

### TC-DEC-09: Feedback increases confidence
- Input: 5 accepted tasks
- Expected: adjusted > original
- Status: PASS (test_adjust_confidence_increase)

### TC-DEC-10: Feedback without data
- Input: no feedback
- Expected: adjusted == original
- Status: PASS (test_adjust_confidence_no_feedback)

## User Model

### TC-USR-01: Statistics — empty
- Input: fresh DB
- Expected: all zeros
- Status: PASS (test_get_statistics_empty)

### TC-USR-02: Statistics — with data
- Input: 3 tasks in DB
- Expected: total_tasks == 3
- Status: PASS (test_get_statistics_with_data)

### TC-USR-03: Acceptance rate
- Input: 1 accepted feedback
- Expected: rate == 100%
- Status: PASS (test_acceptance_rate)

### TC-USR-04: Learner — high acceptance
- Input: 8/10 accepted
- Expected: threshold adjustment < 0 (lower)
- Status: PASS (test_learn_from_feedback_high_acceptance)

### TC-USR-05: Learner — low acceptance
- Input: 2/10 accepted
- Expected: threshold adjustment > 0 (raise)
- Status: PASS (test_learn_from_feedback_low_acceptance)

### TC-USR-06: Learner — insufficient data
- Input: <5 feedbacks
- Expected: adjustment == 0
- Status: PASS (test_learn_insufficient_feedback)

## Integration

### TC-INT-01: Diary to task pipeline
- Input: "Я уже месяц откладываю ремонт машины"
- Expected: task created with status="automatic"
- Status: PASS (test_integration_diary_to_task)

### TC-INT-02: Multiple entries
- Input: 3 diary entries
- Expected: all saved correctly
- Status: PASS (test_integration_multiple_entries)

### TC-INT-03: Confidence routing
- Input: 3 suggestions (90, 65, 30)
- Expected: automatic/suggested/memory
- Status: PASS (test_confidence_routing)

### TC-INT-04: Recurring themes
- Input: 5 random memories
- Expected: clusters returned
- Status: PASS (test_recurring_theme_detection)

## Edge Cases

### TC-EDGE-01: Empty text
- Input: analyze("")
- Expected: empty items, graceful handling

### TC-EDGE-02: Very long text (100k chars)
- Input: long diary entry
- Expected: processed, truncated if needed

### TC-EDGE-03: Special characters
- Input: emoji, unicode, HTML
- Expected: cleaned without errors

### TC-EDGE-04: Binary content
- Input: non-UTF8 content
- Expected: graceful error, no crash

### TC-EDGE-05: Ollama unavailable
- Input: service down
- Expected: empty response, logged error

### TC-EDGE-06: Corrupted DB file
- Input: invalid SQLite file
- Expected: error recovery
