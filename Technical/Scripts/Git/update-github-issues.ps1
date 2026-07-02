param(
  [string]$Repository = "Konstantin2005/ObsiduanMain"
)

$issues = @(
  @{
    Number = 1
    Body = @"
## Development Plan

Feature:
Улучшить интерфейс и стабильность плагина «Жизнь».

Goal:
Сделать панель Live Graph предсказуемой, понятной и устойчивой под реальной нагрузкой.

Business Value:
- Меньше сбоев в повседневном использовании.
- Быстрее анализ и работа с графом.

Risks:
- Сложно отделить UI-баги от runtime-багов.
- Возможны регрессии при ускорении рендера.

Dependencies:
- Базовая state machine панели.
- Проверки на больших графах.

Complexities:
- Интеракции могут конфликтовать с background processing.
- Изменения в одном месте могут ломать восстановление состояния.
"@
  }
  @{
    Number = 2
    Body = @"
## Development Plan

Feature:
Оставить один основной код Live Graph вместо дубликатов.

Goal:
Определить canonical implementation и убрать расхождения между копиями.

Business Value:
- Меньше путаницы при поддержке.
- Меньше риска, что исправления попадут не в тот код.

Risks:
- Можно удалить не ту ветку логики.
- Дубликаты могут отличаться мелкими, но важными правками.

Dependencies:
- Полная инвентаризация всех копий.
- Проверка всех путей импорта и запуска.

Complexities:
- Нужно аккуратно сверить поведение перед удалением дублей.
- Обновление ссылок может затронуть несколько vault'ов.
"@
  }
  @{
    Number = 3
    Body = @"
## Development Plan

Feature:
Уменьшить размер репозитория и убрать сгенерированные файлы.

Goal:
Оставить в репозитории только source of truth и нужные артефакты.

Business Value:
- Репо быстрее и проще в поддержке.
- Меньше шума в ревью и синхронизациях.

Risks:
- Можно удалить полезный snapshot или recovery artifact.
- Generated и source файлы могут быть смешаны.

Dependencies:
- Политика хранения артефактов.
- Инвентаризация логов, билдов и snapshots.

Complexities:
- Требуется аккуратная классификация файлов.
- Нужны правила, чтобы мусор не возвращался обратно.
"@
  }
  @{
    Number = 4
    Body = @"
## Development Plan

Feature:
Синхронизировать настройки производительности и бенчмарков.

Goal:
Привести perf config, benchmark config и runtime behavior к одному контракту.

Business Value:
- Бенчмарки станут сопоставимыми.
- Проще принимать решения по оптимизациям.

Risks:
- Исторические настройки могут использоваться неявно.
- Неверная синхронизация исказит benchmarks.

Dependencies:
- Полный список perf toggles.
- Текущие benchmark сценарии.

Complexities:
- Разные vault'ы могли разойтись в конфигурации.
- Нужна проверка, что старые результаты остаются интерпретируемыми.
"@
  }
  @{
    Number = 5
    Body = @"
## Development Plan

Feature:
Добавить кнопки «Стоп» и «Восстановить» в панель «Жизнь».

Goal:
Дать пользователю управляемую паузу и безопасное продолжение цикла.

Business Value:
- Больше контроля над долгими операциями.
- Меньше страха запускать heavy workflow.

Risks:
- Остановка может оставить состояние частично изменённым.
- Восстановление может не совпасть с ожиданиями пользователя.

Dependencies:
- Чёткая state machine.
- Поддержка resume logic в runtime.

Complexities:
- Нужно гарантировать корректный stop without corruption.
- Риск потерять прогресс цикла при неправильном resume.
"@
  }
  @{
    Number = 6
    Body = @"
## Development Plan

Feature:
Показать прогресс цикла и оставшиеся связи в «Жизни».

Goal:
Сделать выполнение процесса прозрачным.

Business Value:
- Пользователь видит, что происходит сейчас и сколько осталось.
- Проще принимать решение ждать или остановить процесс.

Risks:
- Неверный progress indicator введёт в заблуждение.
- Remaining work может быть трудно вычислить точно.

Dependencies:
- Модель выполнения цикла.
- Метрика remaining connections.

Complexities:
- Прогресс в динамическом графе может быть только оценочным.
- Нужно не перегрузить UI лишними деталями.
"@
  }
  @{
    Number = 7
    Body = @"
## Development Plan

Feature:
Добавить журнал, предпросмотр и безопасное восстановление в «Жизнь».

Goal:
Сделать выполнение отслеживаемым, проверяемым и откатываемым.

Business Value:
- Выше доверие к автоматическим действиям.
- Проще разбирать ошибки и возвращаться назад.

Risks:
- Журнал может быстро разрастаться.
- Restore path может быть сложным и хрупким.

Dependencies:
- Journal format.
- Preview before apply.
- Safe recovery flow.

Complexities:
- Требуется детерминированное восстановление.
- Preview не должен создавать ложное ощущение безопасности.
"@
  }
  @{
    Number = 8
    Body = @"
## Development Plan

Feature:
Настроить синхронизацию Obsidian с Discord.

Goal:
Связать рабочие события и уведомления с Discord workflow.

Business Value:
- Быстрее реагировать на важные изменения.
- Удобнее автоматизировать коммуникацию.

Risks:
- Спам, дубликаты и неправильные уведомления.
- Проблемы с авторизацией и правами доступа.

Dependencies:
- Перечень событий для синхронизации.
- Канал доставки и политика retry.

Complexities:
- Нужно разделить manual и automatic updates.
- Интеграция может потребовать строгих rate limits.
"@
  }
  @{
    Number = 9
    Body = @"
## Development Plan

Feature:
Ускорить обновление графа без полной пересборки.

Goal:
Перейти к incremental update вместо full rebuild.

Business Value:
- Меньше времени ожидания.
- Лучше масштабирование на большие vault'ы.

Risks:
- Можно сломать consistency индекса.
- Incremental path сложно тестировать.

Dependencies:
- Diff model изменений.
- Update pipeline for nodes and edges.

Complexities:
- Нужно корректно учитывать rename/move/delete.
- Сложно сохранить актуальность при частичных изменениях.
"@
  }
  @{
    Number = 10
    Body = @"
## Development Plan

Feature:
Готовить связи людей в фоне и сохранять их в кэш.

Goal:
Вынести expensive link generation из foreground path.

Business Value:
- Быстрее открытие и обновление графа.
- Меньше лагов в UI.

Risks:
- Cache invalidation может ломать актуальность данных.
- Фоновая генерация может конфликтовать с live edits.

Dependencies:
- Background worker.
- Cache storage and invalidation policy.

Complexities:
- Нужно контролировать stale data.
- Необходимо предотвращать гонки между генерацией и чтением.
"@
  }
  @{
    Number = 11
    Body = @"
## Development Plan

Feature:
Перенести расчёт запросов, раскладки и связей в worker pool.

Goal:
Освободить main thread от тяжёлых вычислений.

Business Value:
- Выше responsiveness интерфейса.
- Лучше масштабирование на большие графы.

Risks:
- Синхронизация состояния между workers и UI.
- Сложность отладки параллельного выполнения.

Dependencies:
- Worker API.
- Queue and work item model.

Complexities:
- Serializing large graph data may be expensive.
- Нужны лимиты на параллелизм и backpressure.
"@
  }
  @{
    Number = 12
    Body = @"
## Development Plan

Feature:
Кэшировать раскладку графа для 20K-50K узлов.

Goal:
Избежать повторного дорогого layout calculation.

Business Value:
- Значительно быстрее повторные открытия и обновления.
- Стабильнее UX на больших графах.

Risks:
- Cache key может быть неточным.
- Layout reuse может визуально устаревать.

Dependencies:
- Keying strategy for cached layouts.
- Storage for layout snapshots.

Complexities:
- Нужно учитывать изменение графа без полного пересчёта.
- Большие кэши увеличат storage cost.
"@
  }
  @{
    Number = 13
    Body = @"
## Development Plan

Feature:
Постепенно подгружать связи в плотном графе людей.

Goal:
Перейти от eager loading к progressive loading.

Business Value:
- Быстрее initial render.
- Лучшая управляемость на очень плотных графах.

Risks:
- Пользователь может решить, что граф неполный.
- Сложно сохранить стабильный порядок отображения.

Dependencies:
- Threshold / paging policy.
- Incremental rendering strategy.

Complexities:
- Нужны хорошие loading indicators.
- Частичная загрузка усложняет navigation and search.
"@
  }
  @{
    Number = 14
    Body = @"
## Development Plan

Feature:
Проверить необходимость WebGL/OffscreenCanvas по бенчмаркам.

Goal:
Решать технологический переход только на основании данных.

Business Value:
- Избежать преждевременной сложности.
- Вкладываться только в то, что даёт измеримый выигрыш.

Risks:
- Бенчмарки могут быть шумными или нерепрезентативными.
- Новая технология усложнит поддержку.

Dependencies:
- Benchmark harness.
- Comparable baseline for current renderer.

Complexities:
- Легко оптимизировать тест, а не продукт.
- Нужны реалистичные сценарии нагрузки.
"@
  }
  @{
    Number = 15
    Body = @"
## Development Plan

Feature:
Подключить управление нагрузкой CPU и пропускной способностью.

Goal:
Сделать runtime self-throttling under load.

Business Value:
- Меньше перегрузок и зависаний.
- Стабильнее поведение на разных устройствах.

Risks:
- Слишком агрессивный governor замедлит систему.
- Слишком мягкий governor не даст эффекта.

Dependencies:
- Load measurements.
- Scheduling / backpressure policy.

Complexities:
- Лимиты зависят от железа и размера графа.
- Нужны адаптивные thresholds.
"@
  }
  @{
    Number = 16
    Body = @"
## Development Plan

Feature:
Уплотнять shard-хранилище и восстанавливать manifest.

Goal:
Сократить storage footprint и иметь надежное восстановление.

Business Value:
- Меньше объём данных.
- Более надёжный recovery after partial failures.

Risks:
- Compaction может повредить данные при прерывании.
- Recovery logic может восстановить не тот state.

Dependencies:
- Manifest as source of truth.
- Atomic write/update strategy.

Complexities:
- Нужна детерминированная compaction.
- Manifest recovery должен работать после сбоев.
"@
  }
  @{
    Number = 17
    Body = @"
## Development Plan

Feature:
Убрать полный обход vault из цикла рендера Live Graph.

Goal:
Исключить full scan из hot path рендера.

Business Value:
- Ниже latency.
- Лучше масштабируемость на больших vault'ах.

Risks:
- Полный обход может скрыто использоваться как fallback.
- Index-based path может пропускать edge cases.

Dependencies:
- Indexed update path.
- Verification of visual parity.

Complexities:
- Нужно не потерять актуальность view.
- Сложно отследить скрытые зависимости от full traversal.
"@
  }
  @{
    Number = 18
    Body = @"
## Development Plan

Feature:
Защитить pan, zoom и selection от лагов под нагрузкой.

Goal:
Сохранить smooth interaction на больших графах.

Business Value:
- Лучше ощущение отзывчивости.
- Меньше раздражения у пользователя.

Risks:
- Оптимизация может ухудшить точность interaction.
- Лаги сложно воспроизводить стабильно.

Dependencies:
- Bottleneck analysis.
- Event handling and redraw strategy.

Complexities:
- Interaction может конфликтовать с background rendering.
- Нужно сохранить корректность selection under pressure.
"@
  }
  @{
    Number = 19
    Body = @"
## Development Plan

Feature:
Перенести оставшуюся git-автоматизацию из корня в Technical.

Goal:
Собрать automation, scripts and docs в одном организованном месте.

Business Value:
- Репозиторий становится чище.
- Проще поддерживать и искать нужные сценарии.

Risks:
- Ломаются старые пути запуска.
- Автоматизация может зависеть от корня неявно.

Dependencies:
- Inventory of current scripts.
- Launcher updates.

Complexities:
- Нужно проверить все call sites.
- Есть риск пропустить один из фоновых сценариев.
"@
  }
  @{
    Number = 24
    Body = @"
## Development Plan

Feature:
Зафиксировать единый контракт между live-graph, graph-runtime, storage, workers и UI.

Goal:
Убрать разночтения между частями системы и сделать поведение предсказуемым.

Business Value:
- Меньше регрессий.
- Проще добавлять новые фичи поверх стабильной основы.

Risks:
- Можно задокументировать не тот фактический контракт.
- Слишком жёсткий контракт затруднит развитие.

Dependencies:
- Анализ текущих data flows.
- Согласование между backend, frontend и storage.

Complexities:
- Уже могут быть неявные контракты в старом коде.
- Нужно синхронизировать docs, runtime and tests.
"@
  }
  @{
    Number = 25
    Body = @"
## Development Plan

Feature:
Построить систему изменения графа по diff вместо полной пересборки.

Goal:
Обновлять граф только по реально изменившимся данным.

Business Value:
- Значительно быстрее обновления.
- Меньше лишней работы для storage и render layers.

Risks:
- Consistency bugs after partial updates.
- Сложно корректно обработать rename, move и delete.

Dependencies:
- Change detection layer.
- Incremental pipeline for nodes, edges and layout.

Complexities:
- Нужно безопасно обновлять индекс и manifest по частям.
- Incremental path намного труднее тестировать.
"@
  }
  @{
    Number = 26
    Body = @"
## Development Plan

Feature:
Ввести governor для CPU, memory и throughput.

Goal:
Дать системе возможность сама ограничивать нагрузку.

Business Value:
- Более стабильное поведение under load.
- Меньше лагов и зависаний.

Risks:
- Неправильные лимиты ухудшат throughput.
- Поведение будет сильно зависеть от железа.

Dependencies:
- Benchmark data.
- Backpressure and scheduling policy.

Complexities:
- Нужны адаптивные thresholds.
- Governor должен работать и для background, и для interactive work.
"@
  }
  @{
    Number = 27
    Body = @"
## Development Plan

Feature:
Сделать storage слой, который умеет compaction, recovery и atomic updates.

Goal:
Защитить графовые данные от порчи и разрастания.

Business Value:
- Надёжнее storage.
- Меньше места и проще восстановление.

Risks:
- Частичный сбой может повредить shards.
- Recovery logic может восстановить устаревшее состояние.

Dependencies:
- Manifest as source of truth.
- Atomic write/update strategy.

Complexities:
- Нужно детерминированно обрабатывать прерывания.
- Compaction и recovery нельзя проектировать отдельно.
"@
  }
  @{
    Number = 28
    Body = @"
## Development Plan

Feature:
Формализовать состояния панели «Жизнь» и их переходы.

Goal:
Сделать UI понятным, управляемым и безопасным.

Business Value:
- Пользователь видит, что система делает.
- Меньше ошибок при остановке, восстановлении и preview.

Risks:
- Неправильные state transitions.
- Путаница между UI state и runtime state.

Dependencies:
- Runtime action model.
- UI state mapping.

Complexities:
- Нужна синхронизация между действиями пользователя и фоновыми процессами.
- Ошибки state machine часто проявляются только на длинных сценариях.
"@
  }
  @{
    Number = 29
    Body = @"
## Development Plan

Feature:
Сделать единый benchmark harness и regression gate.

Goal:
Измерять render time, update time, memory, worker load и interaction latency.

Business Value:
- Объективная основа для решений по оптимизации.
- Можно ловить performance regressions до релиза.

Risks:
- Шумные замеры.
- Оптимизация теста вместо продукта.

Dependencies:
- Stable test dataset.
- Baseline storage and reporting.

Complexities:
- Бенчмарки должны быть воспроизводимыми.
- Нужны понятные thresholds, иначе gate будет бесполезным.
"@
  }
  @{
    Number = 30
    Body = @"
## Development Plan

Feature:
Зафиксировать policy для source of truth и generated artifacts.

Goal:
Не допустить повторного разрастания мусора в корне и технических папках.

Business Value:
- Чище репозиторий.
- Проще ревью и сопровождение.

Risks:
- Можно случайно классифицировать нужный файл как generated.
- Без автоматизации policy быстро нарушится.

Dependencies:
- Inventory of repo roots and artifact types.
- Cleanup / ignore rules.

Complexities:
- Нужны ясные правила для teams and scripts.
- Политика должна учитывать vault snapshots и build outputs.
"@
  }
  @{
    Number = 31
    Body = @"
## Development Plan

Feature:
Ввести единый стандарт docs, execution log и traceability.

Goal:
Сделать связи issue -> branch -> PR -> verification прозрачными.

Business Value:
- Меньше хаоса в коммуникации.
- Проще понять статус задач.

Risks:
- Избыточная бюрократия.
- Шаблон могут перестать использовать.

Dependencies:
- PR workflow.
- Issue naming and logging conventions.

Complexities:
- Формат должен быть лёгким, иначе его начнут обходить.
- Нужно поддерживать единый стиль во всех рабочих папках.
"@
  }
)

foreach ($issue in $issues) {
  $bodyFile = Join-Path $env:TEMP ("issue-body-{0}.md" -f ([guid]::NewGuid().ToString("N")))
  Set-Content -Path $bodyFile -Value $issue.Body -Encoding utf8
  if ($issue.ContainsKey("Title")) {
    gh issue create -R $Repository --title $issue.Title --body-file $bodyFile | Out-Null
  } else {
    gh issue edit $issue.Number -R $Repository --body-file $bodyFile | Out-Null
  }
  Remove-Item -Path $bodyFile -Force
}
