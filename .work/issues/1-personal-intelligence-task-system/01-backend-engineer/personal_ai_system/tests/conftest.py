import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest
from memory.database import Database
from memory.storage import Storage
from memory.models import Entry, Memory


@pytest.fixture
def db():
    database = Database(":memory:")
    database.create_schema()
    yield database
    database.close()


@pytest.fixture
def storage(db):
    return Storage(db)


@pytest.fixture
def sample_entries(storage):
    entries = []
    texts = [
        "Я уже месяц откладываю ремонт машины. Нужно записаться в сервис.",
        "Надо заняться машиной, давно пора.",
        "Купил продукты на неделю.",
        "Надо бы разобраться с проблемой на работе.",
        "Начал учить английский, но бросил после недели.",
        "Я обещал маме помочь с переездом.",
        "Опять этот проект тормозит из-за бюрократии.",
        "Хочу начать бегать по утрам.",
        "Нужно обновить резюме.",
        "Когда-нибудь надо разобрать гараж.",
    ]
    for text in texts:
        entry = Entry(source="test", raw_text=text, cleaned_text=text)
        eid = storage.save_entry(entry)
        entries.append(eid)
    return entries


@pytest.fixture
def sample_memories(storage, sample_entries):
    mem_ids = []
    for eid in sample_entries:
        entry = storage.get_entry(eid)
        mem = Memory(entry_id=eid, content=entry.cleaned_text, memory_type="thought", confidence=50.0)
        mid = storage.save_memory(mem)
        mem_ids.append(mid)
    return mem_ids
