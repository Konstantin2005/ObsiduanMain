import pytest
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "01-backend-engineer", "personal_ai_system"))

from memory.database import Database
from memory.storage import Storage
from memory.models import Entry, Memory, Task, Suggestion
from analyzer.parser import ResponseParser
from analyzer.validator import Validator
from decision_engine.router import DecisionRouter
from ingestion.cleaner import Cleaner
from ingestion.loader import Loader


class TestEdgeCasesMemory:
    def test_empty_entry(self, storage):
        entry = Entry(source="test", raw_text="", cleaned_text="")
        eid = storage.save_entry(entry)
        assert eid > 0
        fetched = storage.get_entry(eid)
        assert fetched.raw_text == ""

    def test_unicode_text(self, storage):
        text = "Привет, мир! 🌍 日本語 中文 español"
        entry = Entry(source="test", raw_text=text)
        eid = storage.save_entry(entry)
        fetched = storage.get_entry(eid)
        assert fetched.raw_text == text

    def test_very_long_text(self, storage):
        text = "A" * 100000
        entry = Entry(source="test", raw_text=text)
        eid = storage.save_entry(entry)
        assert eid > 0

    def test_special_chars(self, storage):
        text = "<script>alert('xss')</script> \n\t\r\x00"
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


class TestEdgeCasesAnalyzer:
    def test_empty_string_parse(self):
        parser = ResponseParser()
        result = parser.parse("")
        assert result == []

    def test_none_response_parse(self):
        parser = ResponseParser()
        result = parser.parse(None)
        assert result == []

    def test_json_with_extra_text(self):
        parser = ResponseParser()
        text = "Here's what I found:\n\n{\"items\": [{\"type\": \"task\", \"title\": \"Test\", \"confidence\": 50, \"reason\": \"test\", \"recommended_action\": \"do it\"}]}\n\nLet me know if you need more."
        result = parser.parse(text)
        assert len(result) == 1

    def test_invalid_json_repair(self):
        parser = ResponseParser()
        text = '{"items": [{"type": "task", "title": "Test", "confidence": 50, "reason": "test", "recommended_action": "do it",}]}'
        result = parser.parse(text)
        assert len(result) == 1

    def test_validator_empty_list(self):
        validator = Validator()
        assert validator.validate([]) == []


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


class TestEdgeCasesIngestion:
    def test_empty_file(self, tmp_path):
        f = tmp_path / "empty.txt"
        f.write_text("", encoding="utf-8")
        loader = Loader()
        content = loader.load_file(str(f))
        assert content == ""

    def test_binary_content(self, tmp_path):
        f = tmp_path / "binary.txt"
        f.write_bytes(b"\x00\x01\x02\xFF")
        loader = Loader()
        content = loader.load_file(str(f))
        assert content is not None

    def test_mixed_language(self):
        cleaner = Cleaner()
        text = "English 中文 Русский 日本語 한국어"
        cleaned = cleaner.clean(text)
        assert "English" in cleaned

    def test_cleaner_with_markdown_tables(self):
        cleaner = Cleaner()
        text = "| Col1 | Col2 |\n|------|------|\n| A    | B    |"
        cleaned = cleaner.clean(text)
        assert cleaned is not None

    def test_parser_no_separator(self):
        parser = Parser()
        entries = parser.split_entries("Just one continuous paragraph without any separator.")
        assert len(entries) == 1
