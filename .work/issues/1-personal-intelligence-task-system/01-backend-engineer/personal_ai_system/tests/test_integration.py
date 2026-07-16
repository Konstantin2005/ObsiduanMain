import pytest
from memory.database import Database
from memory.storage import Storage
from memory.search import SearchEngine
from memory.models import Entry, Memory, Task
from analyzer.parser import ResponseParser
from analyzer.validator import Validator
from decision_engine.router import DecisionRouter
from decision_engine.dedup import DedupChecker
from ingestion.cleaner import Cleaner
from memory.models import Suggestion, Entry


class TestFullPipeline:
    @pytest.fixture
    def system(self):
        db = Database(":memory:")
        db.create_schema()
        storage = Storage(db)
        search = SearchEngine(db)
        decision = DecisionRouter(storage)
        return {"db": db, "storage": storage, "search": search, "decision": decision}

    def test_integration_diary_to_task(self, system):
        diary_text = "Я уже месяц откладываю ремонт машины. Нужно записаться в сервис."
        cleaner = Cleaner()
        cleaned = cleaner.clean(diary_text)

        entry = Entry(source="test", raw_text=diary_text, cleaned_text=cleaned)
        entry_id = system["storage"].save_entry(entry)

        mem = Memory(entry_id=entry_id, content=cleaned, memory_type="thought", confidence=50.0)
        system["storage"].save_memory(mem)

        parser = ResponseParser()
        suggestions = parser.parse(
            '{"items": [{"type": "task", "title": "Записаться в сервис", "confidence": 90, "reason": "Прямое упоминание задачи", "recommended_action": "Позвонить и записаться"}]}'
        )

        validator = Validator()
        valid = validator.validate(suggestions)
        assert len(valid) == 1
        assert valid[0].title == "Записаться в сервис"

        tasks = system["decision"].route(valid, entry_id)
        assert len(tasks) == 1
        assert tasks[0].status == "automatic"
        assert tasks[0].title == "Записаться в сервис"

    def test_integration_multiple_entries(self, system):
        texts = [
            "Опять откладываю ремонт машины",
            "Надо заняться машиной",
            "Купил продукты",
        ]
        for text in texts:
            entry = Entry(source="test", raw_text=text, cleaned_text=text)
            eid = system["storage"].save_entry(entry)
            mem = Memory(entry_id=eid, content=text, memory_type="thought", confidence=50.0)
            system["storage"].save_memory(mem)

        all_entries = system["storage"].get_all_entries()
        assert len(all_entries) == 3

        all_mems = system["storage"].get_all_memories()
        assert len(all_mems) == 3

    def test_confidence_routing(self, system):
        entry = Entry(source="test", raw_text="Test entry", cleaned_text="Test entry")
        eid = system["storage"].save_entry(entry)
        router = DecisionRouter(system["storage"], auto_threshold=85.0, suggest_threshold=50.0)
        suggestions = [
            Suggestion(type="task", title="Auto task", confidence=90, reason="High", recommended_action="Do"),
            Suggestion(type="task", title="Suggest task", confidence=65, reason="Medium", recommended_action="Do"),
            Suggestion(type="task", title="Memory only", confidence=30, reason="Low", recommended_action="Do"),
        ]
        tasks = router.route(suggestions, eid)
        assert len(tasks) == 3
        statuses = {t.title: t.status for t in tasks}
        assert statuses["Auto task"] == "automatic"
        assert statuses["Suggest task"] == "suggested"
        assert statuses["Memory only"] == "memory"

    def test_recurring_theme_detection(self, system):
        search = system["search"]
        memories = []
        import numpy as np
        rng = np.random.default_rng(42)
        for i in range(5):
            vec = rng.random(384).astype(np.float32)
            mem = Memory(entry_id=i, content=f"Memory {i}", embedding=vec.tobytes(), memory_type="thought")
            memories.append(mem)
        clusters = search.find_recurring_themes(memories, threshold=0.9)
        assert isinstance(clusters, list)
