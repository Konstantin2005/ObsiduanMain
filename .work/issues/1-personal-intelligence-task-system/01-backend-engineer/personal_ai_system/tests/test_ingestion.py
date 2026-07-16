import pytest
import os
import tempfile
from ingestion.loader import Loader
from ingestion.parser import Parser
from ingestion.cleaner import Cleaner


class TestLoader:
    def test_load_text(self):
        loader = Loader()
        source, text = loader.load_text("Hello world", source="manual")
        assert source == "manual"
        assert text == "Hello world"

    def test_load_file(self):
        loader = Loader()
        path = ""
        try:
            with tempfile.NamedTemporaryFile(mode="w", suffix=".txt", delete=False) as f:
                f.write("Test diary entry")
                path = f.name
            content = loader.load_file(path)
            assert content == "Test diary entry"
        finally:
            if path and os.path.exists(path):
                os.unlink(path)

    def test_load_file_unsupported(self):
        loader = Loader()
        path = ""
        try:
            with tempfile.NamedTemporaryFile(mode="w", suffix=".pdf", delete=False) as f:
                f.write("fake")
                path = f.name
            content = loader.load_file(path)
            assert content is None
        finally:
            if path and os.path.exists(path):
                os.unlink(path)

    def test_load_missing_file(self):
        loader = Loader()
        content = loader.load_file("nonexistent.txt")
        assert content is None


class TestParser:
    def test_split_entries(self):
        parser = Parser()
        text = "First entry\n\n---\n\nSecond entry"
        entries = parser.split_entries(text)
        assert len(entries) == 2
        assert "First entry" in entries[0]

    def test_extract_date(self):
        parser = Parser()
        text = "Today 2024-01-15 I went to the store"
        meta = parser.extract_metadata(text)
        assert "2024-01-15" in meta.get("date", "")

    def test_extract_tags(self):
        parser = Parser()
        text = "I need to #fix the #car"
        meta = parser.extract_metadata(text)
        assert "fix" in meta.get("tags", [])
        assert "car" in meta.get("tags", [])


class TestCleaner:
    def test_clean_markdown_links(self):
        cleaner = Cleaner()
        text = "Check [this link](http://example.com)"
        cleaned = cleaner.clean(text)
        assert "http://example.com" not in cleaned
        assert "this link" in cleaned

    def test_clean_markdown_headers(self):
        cleaner = Cleaner()
        text = "## Header\n\nContent"
        cleaned = cleaner.clean(text)
        assert "##" not in cleaned

    def test_clean_urls(self):
        cleaner = Cleaner()
        text = "Visit http://example.com/page"
        cleaned = cleaner.clean(text)
        assert "http://" not in cleaned
        assert "[URL]" in cleaned

    def test_clean_empty(self):
        cleaner = Cleaner()
        assert cleaner.clean("") == ""
