import numpy as np
from typing import List, Tuple, Optional
from .database import Database
from .models import Memory


class SearchEngine:
    def __init__(self, db: Database):
        self.db = db
        self._embedding_dim = 384

    def _bytes_to_vector(self, blob: bytes) -> np.ndarray:
        return np.frombuffer(blob, dtype=np.float32)

    def _vector_to_bytes(self, vector: np.ndarray) -> bytes:
        return vector.astype(np.float32).tobytes()

    def cosine_similarity(self, a: np.ndarray, b: np.ndarray) -> float:
        dot = np.dot(a, b)
        norm_a = np.linalg.norm(a)
        norm_b = np.linalg.norm(b)
        if norm_a == 0 or norm_b == 0:
            return 0.0
        return float(dot / (norm_a * norm_b))

    def find_similar(self, query_vector: np.ndarray, top_k: int = 5, min_score: float = 0.5) -> List[Tuple[Memory, float]]:
        rows = self.db.fetch_all("SELECT * FROM memories WHERE embedding IS NOT NULL")
        if not rows:
            return []
        results = []
        for row in rows:
            mem = Memory(**dict(row))
            vec = self._bytes_to_vector(mem.embedding)
            score = self.cosine_similarity(query_vector, vec)
            if score >= min_score:
                results.append((mem, score))
        results.sort(key=lambda x: x[1], reverse=True)
        return results[:top_k]

    def find_related_by_text(self, text: str, all_memories: List[Memory], top_k: int = 5) -> List[Tuple[Memory, float]]:
        if not all_memories:
            return []
        query_vec = self._compute_text_embedding(text)
        results = []
        for mem in all_memories:
            if mem.embedding:
                vec = self._bytes_to_vector(mem.embedding)
                score = self.cosine_similarity(query_vec, vec)
                results.append((mem, score))
        results.sort(key=lambda x: x[1], reverse=True)
        return results[:top_k]

    def find_recurring_themes(self, memories: List[Memory], threshold: float = 0.75) -> List[List[Memory]]:
        if len(memories) < 2:
            return []
        clusters = []
        used = set()
        for i, m1 in enumerate(memories):
            if i in used:
                continue
            cluster = [m1]
            used.add(i)
            for j, m2 in enumerate(memories):
                if j in used or not m1.embedding or not m2.embedding:
                    continue
                v1 = self._bytes_to_vector(m1.embedding)
                v2 = self._bytes_to_vector(m2.embedding)
                sim = self.cosine_similarity(v1, v2)
                if sim >= threshold:
                    cluster.append(m2)
                    used.add(j)
            if len(cluster) > 1:
                clusters.append(cluster)
        return clusters

    def _compute_text_embedding(self, text: str) -> np.ndarray:
        rng = np.random.default_rng(hash(text) & 0xFFFFFFFF)
        return rng.random(self._embedding_dim).astype(np.float32)
