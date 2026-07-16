import pytest
from analyzer.parser import ResponseParser
from analyzer.validator import Validator
from memory.models import Suggestion


class TestResponseParser:
    def test_parse_valid_json(self):
        parser = ResponseParser()
        response = '{"items": [{"type": "task", "title": "Fix the car", "confidence": 85, "reason": "Explicit mention", "recommended_action": "Schedule service"}]}'
        suggestions = parser.parse(response)
        assert len(suggestions) == 1
        assert suggestions[0].type == "task"
        assert suggestions[0].title == "Fix the car"
        assert suggestions[0].confidence == 85.0

    def test_parse_no_items(self):
        parser = ResponseParser()
        response = '{"items": []}'
        suggestions = parser.parse(response)
        assert len(suggestions) == 0

    def test_parse_malformed_json(self):
        parser = ResponseParser()
        response = "not json at all"
        suggestions = parser.parse(response)
        assert len(suggestions) == 0

    def test_parse_json_in_text(self):
        parser = ResponseParser()
        response = "Here is the analysis:\n\n{\"items\": [{\"type\": \"task\", \"title\": \"Test\", \"confidence\": 50, \"reason\": \"test\", \"recommended_action\": \"do it\"}]}\n\nDone."
        suggestions = parser.parse(response)
        assert len(suggestions) == 1
        assert suggestions[0].title == "Test"

    def test_parse_multiple_items(self):
        parser = ResponseParser()
        response = '{"items": [{"type": "task", "title": "Task 1", "confidence": 90, "reason": "a", "recommended_action": "x"}, {"type": "goal", "title": "Goal 1", "confidence": 70, "reason": "b", "recommended_action": "y"}]}'
        suggestions = parser.parse(response)
        assert len(suggestions) == 2


class TestValidator:
    def test_valid_suggestion(self):
        validator = Validator()
        s = Suggestion(type="task", title="Fix car", confidence=85, reason="Explicit", recommended_action="Do it")
        assert validator._is_valid(s)

    def test_invalid_type(self):
        validator = Validator()
        s = Suggestion(type="invalid", title="Test", confidence=50, reason="Test", recommended_action="Test")
        assert not validator._is_valid(s)

    def test_invalid_confidence(self):
        validator = Validator()
        s = Suggestion(type="task", title="Test", confidence=150, reason="Test", recommended_action="Test")
        assert not validator._is_valid(s)

    def test_short_title(self):
        validator = Validator()
        s = Suggestion(type="task", title="AB", confidence=50, reason="Test reason", recommended_action="Test")
        assert not validator._is_valid(s)

    def test_is_actionable(self):
        validator = Validator()
        s = Suggestion(type="task", title="Fix car", confidence=85, reason="Need to", recommended_action="Do it")
        assert validator.is_actionable(s)

    def test_not_actionable_low_confidence(self):
        validator = Validator()
        s = Suggestion(type="task", title="Fix car", confidence=20, reason="Need to", recommended_action="Do it")
        assert not validator.is_actionable(s)

    def test_not_actionable_vague(self):
        validator = Validator()
        s = Suggestion(type="task", title="maybe someday fix car", confidence=80, reason="Need to", recommended_action="Do it")
        assert not validator.is_actionable(s)


class TestEdgeCasesAnalyzer:
    def test_empty_string_parse(self):
        parser = ResponseParser()
        result = parser.parse("")
        assert result == []

    def test_none_response_parse(self):
        parser = ResponseParser()
        result = parser.parse(None)
        assert result == []

    def test_invalid_json_repair(self):
        parser = ResponseParser()
        text = '{"items": [{"type": "task", "title": "Test", "confidence": 50, "reason": "test", "recommended_action": "do it",}]}'
        result = parser.parse(text)
        assert len(result) == 1

    def test_validator_empty_list(self):
        validator = Validator()
        assert validator.validate([]) == []

    def test_json_with_extra_text(self):
        parser = ResponseParser()
        text = "Here's what I found:\n\n{\"items\": [{\"type\": \"task\", \"title\": \"Test\", \"confidence\": 50, \"reason\": \"test\", \"recommended_action\": \"do it\"}]}\n\nLet me know if you need more."
        result = parser.parse(text)
        assert len(result) == 1
