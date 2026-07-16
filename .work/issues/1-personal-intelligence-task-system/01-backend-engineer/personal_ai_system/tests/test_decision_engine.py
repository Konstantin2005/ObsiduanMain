import pytest
from decision_engine.router import DecisionRouter
from decision_engine.dedup import DedupChecker
from decision_engine.feedback import FeedbackLearner
from memory.models import Suggestion, Task, Feedback


class TestDecisionRouter:
    def test_auto_threshold(self, storage, sample_entries):
        router = DecisionRouter(storage, auto_threshold=85.0, suggest_threshold=50.0)
        suggestions = [
            Suggestion(type="task", title="High confidence task", confidence=90, reason="Test", recommended_action="Do"),
        ]
        tasks = router.route(suggestions, sample_entries[0])
        assert len(tasks) == 1
        assert tasks[0].status == "automatic"

    def test_suggest_threshold(self, storage, sample_entries):
        router = DecisionRouter(storage, auto_threshold=85.0, suggest_threshold=50.0)
        suggestions = [
            Suggestion(type="task", title="Medium confidence", confidence=65, reason="Test", recommended_action="Do"),
        ]
        tasks = router.route(suggestions, sample_entries[0])
        assert len(tasks) == 1
        assert tasks[0].status == "suggested"

    def test_memory_threshold(self, storage, sample_entries):
        router = DecisionRouter(storage, auto_threshold=85.0, suggest_threshold=50.0)
        suggestions = [
            Suggestion(type="task", title="Low confidence", confidence=30, reason="Test", recommended_action="Do"),
        ]
        tasks = router.route(suggestions, sample_entries[0])
        assert len(tasks) == 1
        assert tasks[0].status == "memory"

    def test_custom_thresholds(self, storage, sample_entries):
        router = DecisionRouter(storage, auto_threshold=90.0, suggest_threshold=60.0)
        assert router.auto_threshold == 90.0
        assert router.suggest_threshold == 60.0

    def test_set_thresholds(self, storage, sample_entries):
        router = DecisionRouter(storage)
        router.set_thresholds(95.0, 55.0)
        assert router.auto_threshold == 95.0
        assert router.suggest_threshold == 55.0


class TestDedupChecker:
    def test_exact_duplicate(self, storage):
        task = Task(title="Fix the car", confidence=80, status="suggested")
        storage.save_task(task)
        checker = DedupChecker(storage)
        assert checker.is_duplicate("Fix the car")

    def test_similar_duplicate(self, storage):
        task = Task(title="Fix the car", confidence=80, status="suggested")
        storage.save_task(task)
        checker = DedupChecker(storage)
        assert checker.is_duplicate("fix car")

    def test_no_duplicate(self, storage):
        task = Task(title="Fix the car", confidence=80, status="suggested")
        storage.save_task(task)
        checker = DedupChecker(storage)
        assert not checker.is_duplicate("Buy groceries")

    def test_empty_db(self, storage):
        checker = DedupChecker(storage)
        assert not checker.is_duplicate("Anything")


class TestFeedbackLearner:
    def test_adjust_confidence_increase(self, storage, sample_entries):
        task = Task(title="Test task", confidence=80, status="suggested", source_entry_id=sample_entries[0])
        tid = storage.save_task(task)
        for _ in range(5):
            storage.save_feedback(Feedback(task_id=tid, decision="accepted"))
        learner = FeedbackLearner(storage)
        suggestion = Suggestion(type="task", title="New task", confidence=70, reason="Test", recommended_action="Do")
        adjusted = learner.adjust_confidence(suggestion)
        assert adjusted > 70

    def test_adjust_confidence_no_feedback(self, storage):
        learner = FeedbackLearner(storage)
        suggestion = Suggestion(type="task", title="Test", confidence=70, reason="a", recommended_action="b")
        adjusted = learner.adjust_confidence(suggestion)
        assert adjusted == 70


class TestEdgeCasesDecision:
    def test_zero_confidence(self, storage, sample_entries):
        router = DecisionRouter(storage)
        suggestions = [Suggestion(type="task", title="Test", confidence=0, reason="", recommended_action="")]
        tasks = router.route(suggestions, sample_entries[0])
        assert len(tasks) == 1
        assert tasks[0].status == "memory"

    def test_max_confidence(self, storage, sample_entries):
        router = DecisionRouter(storage)
        suggestions = [Suggestion(type="task", title="Test", confidence=100, reason="High", recommended_action="Do")]
        tasks = router.route(suggestions, sample_entries[0])
        assert len(tasks) == 1
        assert tasks[0].status == "automatic"

    def test_boundary_auto(self, storage, sample_entries):
        router = DecisionRouter(storage, auto_threshold=85.0, suggest_threshold=50.0)
        suggestions = [Suggestion(type="task", title="Test", confidence=85, reason="Exact auto", recommended_action="Do")]
        tasks = router.route(suggestions, sample_entries[0])
        assert tasks[0].status == "automatic"

    def test_boundary_suggest(self, storage, sample_entries):
        router = DecisionRouter(storage, auto_threshold=85.0, suggest_threshold=50.0)
        suggestions = [Suggestion(type="task", title="Test", confidence=50, reason="Exact suggest", recommended_action="Do")]
        tasks = router.route(suggestions, sample_entries[0])
        assert tasks[0].status == "suggested"

    def test_boundary_memory(self, storage, sample_entries):
        router = DecisionRouter(storage, auto_threshold=85.0, suggest_threshold=50.0)
        suggestions = [Suggestion(type="task", title="Test", confidence=49, reason="Just below", recommended_action="Do")]
        tasks = router.route(suggestions, sample_entries[0])
        assert tasks[0].status == "memory"
