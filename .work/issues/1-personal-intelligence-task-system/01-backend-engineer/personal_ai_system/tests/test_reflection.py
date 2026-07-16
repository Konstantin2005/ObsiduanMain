import pytest
from reflection.daily import DailyReflection
from reflection.weekly import WeeklyReflection
from memory.models import Task


class TestDailyReflection:
    def test_generate_empty(self, storage):
        reflection = DailyReflection(storage)
        report = reflection.generate()
        assert "date" in report
        assert report["new_entries"] == 0

    def test_generate_with_data(self, storage, sample_entries):
        for eid in sample_entries[:3]:
            task = Task(title="Task", confidence=80, status="suggested", source_entry_id=eid)
            storage.save_task(task)

        reflection = DailyReflection(storage)
        report = reflection.generate()
        assert report["new_entries"] >= 0
        assert "open_automatic_tasks" in report


class TestWeeklyReflection:
    def test_generate_empty(self, storage):
        reflection = WeeklyReflection(storage)
        report = reflection.generate()
        assert "period" in report
        assert report["new_entries"] == 0

    def test_generate_with_data(self, storage, sample_entries, sample_memories):
        reflection = WeeklyReflection(storage)
        report = reflection.generate()
        assert report["total_entries"] == 10
        assert report["total_memories"] == 10
