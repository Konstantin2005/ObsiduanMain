SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS entries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    source TEXT NOT NULL DEFAULT 'manual',
    raw_text TEXT NOT NULL,
    cleaned_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_file TEXT
);

CREATE TABLE IF NOT EXISTS memories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entry_id INTEGER NOT NULL REFERENCES entries(id),
    content TEXT NOT NULL,
    embedding BLOB,
    memory_type TEXT NOT NULL DEFAULT 'fact',
    confidence REAL DEFAULT 0.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    memory_id INTEGER REFERENCES memories(id),
    title TEXT NOT NULL,
    description TEXT,
    confidence REAL DEFAULT 0.0,
    status TEXT NOT NULL DEFAULT 'memory',
    source_entry_id INTEGER REFERENCES entries(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS relationships (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    source_memory_id INTEGER NOT NULL REFERENCES memories(id),
    target_memory_id INTEGER NOT NULL REFERENCES memories(id),
    relation_type TEXT NOT NULL,
    strength REAL DEFAULT 0.5,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS feedback (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id INTEGER NOT NULL REFERENCES tasks(id),
    decision TEXT NOT NULL,
    reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_memories_type ON memories(memory_type);
CREATE INDEX IF NOT EXISTS idx_memories_entry ON memories(entry_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_confidence ON tasks(confidence);
"""
