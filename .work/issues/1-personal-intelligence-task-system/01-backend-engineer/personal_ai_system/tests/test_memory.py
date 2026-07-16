import pytest
from memory.models import Entry, Memory, Task, Feedback, Suggestion
from memory.storage import Storage
from memory.search import SearchEngine


class TestEntryStorage:
    def test_save_entry(self, storage):
        entry = Entry(source="test", raw_text="Hello world")
        eid = storage.save_entry(entry)
        assert eid is not None and eid > 0

    def test_get_entry(self, storage):
        entry = Entry(source="test", raw_text="Test entry")
        eid = storage.save_entry(entry)
        fetched = storage.get_entry(eid)
        assert fetched is not None
        assert fetched.raw_text == "Test entry"

    def test_get_all_entries(self, storage, sample_entries):
        entries = storage.get_all_entries()
        assert len(entries) == 10

    def test_save_ten_entries(self, storage, sample_entries):
        entries = storage.get_all_entries()
        assert len(entries) == 10
        assert all(e.raw_text for e in entries)


class TestMemoryStorage:
    def test_save_memory(self, storage, sample_entries):
        mem = Memory(entry_id=sample_entries[0], content="Test memory", memory_type="fact", confidence=80.0)
        mid = storage.save_memory(mem)
        assert mid is not None and mid > 0

    def test_get_memory(self, storage, sample_entries):
        mem = Memory(entry_id=sample_entries[0], content="Test", memory_type="fact")
        mid = storage.save_memory(mem)
        fetched = storage.get_memory(mid)
        assert fetched is not None
        assert fetched.content == "Test"

    def test_get_memories_by_type(self, storage, sample_entries):
        for i, eid in enumerate(sample_entries[:5]):
            mem = Memory(entry_id=eid, content=f"Memory {i}", memory_type="task", confidence=90.0)
            storage.save_memory(mem)
        memories = storage.get_memories_by_type("task")
        assert len(memories) == 5

    def test_get_all_memories(self, storage, sample_memories):
        all_mems = storage.get_all_memories()
        assert len(all_mems) == 10


class TestTaskStorage:
    def test_save_task(self, storage, sample_entries):
        task = Task(
            title="Test task",
            description="Description",
            confidence=85.0,
            status="automatic",
            source_entry_id=sample_entries[0],
        )
        tid = storage.save_task(task)
        assert tid is not None and tid > 0

    def test_update_task_status(self, storage, sample_entries):
        task = Task(title="Task", confidence=50.0, status="suggested", source_entry_id=sample_entries[0])
        tid = storage.save_task(task)
        storage.update_task_status(tid, "approved")
        tasks = storage.get_tasks_by_status("approved")
        assert any(t.id == tid for t in tasks)

    def test_get_tasks_by_status(self, storage, sample_entries):
        for i in range(3):
            task = Task(title=f"Task {i}", confidence=70.0, status="suggested", source_entry_id=sample_entries[0])
            storage.save_task(task)
        tasks = storage.get_tasks_by_status("suggested")
        assert len(tasks) == 3


class TestSearchEngine:
    def test_cosine_similarity(self, db):
        engine = SearchEngine(db)
        import numpy as np
        a = np.array([1.0, 0.0, 0.0])
        b = np.array([1.0, 0.0, 0.0])
        assert abs(engine.cosine_similarity(a, b) - 1.0) < 0.001

        c = np.array([1.0, 0.0, 0.0])
        d = np.array([0.0, 1.0, 0.0])
        assert abs(engine.cosine_similarity(c, d) - 0.0) < 0.001

    def test_similarity_orthogonal(self, db):
        engine = SearchEngine(db)
        import numpy as np
        a = np.array([0.0, 1.0])
        b = np.array([1.0, 0.0])
        assert abs(engine.cosine_similarity(a, b)) < 0.001


class TestFeedbackStorage:
    def test_save_feedback(self, storage, sample_entries):
        task = Task(title="Test", confidence=80.0, status="suggested", source_entry_id=sample_entries[0])
        tid = storage.save_task(task)
        fb = Feedback(task_id=tid, decision="accepted", reason="Good task")
        fid = storage.save_feedback(fb)
        assert fid is not None and fid > 0

    def test_get_feedback_for_task(self, storage, sample_entries):
        task = Task(title="Test", confidence=80.0, status="suggested", source_entry_id=sample_entries[0])
        tid = storage.save_task(task)
        for decision in ["accepted", "rejected"]:
            storage.save_feedback(Feedback(task_id=tid, decision=decision))
        feedbacks = storage.get_feedback_for_task(tid)
        assert len(feedbacks) >= 2


class TestEdgeCasesMemory:
    def test_empty_entry(self, storage):
        entry = Entry(source="test", raw_text="", cleaned_text="")
        eid = storage.save_entry(entry)
        assert eid > 0
        fetched = storage.get_entry(eid)
        assert fetched.raw_text == ""

    def test_unicode_text(self, storage):
        text = "Привет, мир! 日本語 中文 español"
        entry = Entry(source="test", raw_text=text)
        eid = storage.save_entry(entry)
        fetched = storage.get_entry(eid)
        assert fetched.raw_text == text

    def test_special_chars(self, storage):
        text = "<script>alert('xss')</script> \t\n\r"
        entry = Entry(source="test", raw_text=text)
        eid = storage.save_entry(entry)
        fetched = storage.get_entry(eid)
        assert fetched is not None

    def test_zero_confidence_memory(self, storage, sample_entries):
        mem = Memory(entry_id=sample_entries[0], content="Zero confidence", memory_type="fact", confidence=0.0)
        mid = storage.save_memory(mem)
        assert mid > 0
        fetched = storage.get_memory(mid)
        assert fetched.confidence == 0.0
