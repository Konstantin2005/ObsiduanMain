import pytest
from user_model.profile import UserProfile
from user_model.learner import Learner
from memory.models import Task, Feedback


class TestUserProfile:
    def test_get_statistics_empty(self, storage):
        profile = UserProfile(storage)
        stats = profile.get_statistics()
        assert stats["total_entries"] == 0
        assert stats["total_tasks"] == 0

    def test_get_statistics_with_data(self, storage, sample_entries):
        for i, eid in enumerate(sample_entries[:3]):
            task = Task(title=f"Task {i}", confidence=80, status="suggested", source_entry_id=eid)
            storage.save_task(task)

        profile = UserProfile(storage)
        stats = profile.get_statistics()
        assert stats["total_entries"] == 10
        assert stats["total_tasks"] == 3

    def test_acceptance_rate(self, storage, sample_entries):
        task = Task(title="Test", confidence=80, status="suggested", source_entry_id=sample_entries[0])
        tid = storage.save_task(task)
        storage.save_feedback(Feedback(task_id=tid, decision="accepted"))

        profile = UserProfile(storage)
        stats = profile.get_statistics()
        assert stats["accepted"] == 1
        assert stats["acceptance_rate"] == 100.0


class TestLearner:
    def test_learn_from_feedback_high_acceptance(self, storage, sample_entries):
        task = Task(title="Test", confidence=80, status="suggested", source_entry_id=sample_entries[0])
        tid = storage.save_task(task)
        for _ in range(8):
            storage.save_feedback(Feedback(task_id=tid, decision="accepted"))
        for _ in range(2):
            storage.save_feedback(Feedback(task_id=tid, decision="rejected"))

        learner = Learner(storage)
        learner.learn_from_feedback()
        assert learner.auto_threshold_adjustment < 0

    def test_learn_from_feedback_low_acceptance(self, storage, sample_entries):
        task = Task(title="Test", confidence=80, status="suggested", source_entry_id=sample_entries[0])
        tid = storage.save_task(task)
        for _ in range(2):
            storage.save_feedback(Feedback(task_id=tid, decision="accepted"))
        for _ in range(8):
            storage.save_feedback(Feedback(task_id=tid, decision="rejected"))

        learner = Learner(storage)
        learner.learn_from_feedback()
        assert learner.auto_threshold_adjustment > 0

    def test_learn_insufficient_feedback(self, storage):
        learner = Learner(storage)
        learner.learn_from_feedback()
        assert learner.auto_threshold_adjustment == 0.0
