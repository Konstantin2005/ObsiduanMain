import json
import logging
import requests
from typing import Optional
from memory.models import Task

logger = logging.getLogger("pits.nirvana")


class NirvanaBridge:
    def __init__(self, bridge_url: str = "http://localhost:8712", api_key: Optional[str] = None):
        self.bridge_url = bridge_url
        self.api_key = api_key
        self.headers = {"Content-Type": "application/json"}
        if api_key:
            self.headers["Authorization"] = f"Bearer {api_key}"

    def create_task(self, task: Task) -> bool:
        payload = {
            "title": task.title,
            "description": task.description or "",
            "source": "pits",
            "confidence": task.confidence,
        }
        try:
            resp = requests.post(
                f"{self.bridge_url}/api/tasks",
                json=payload,
                headers=self.headers,
                timeout=10,
            )
            if resp.status_code in (200, 201):
                logger.info("Task created in Nirvana: %s (id=%s)", task.title, resp.json().get("id"))
                return True
            logger.warning("Nirvana returned status %s: %s", resp.status_code, resp.text)
            return False
        except requests.ConnectionError:
            logger.error("Cannot connect to Nirvana Bridge at %s", self.bridge_url)
            return False
        except Exception as e:
            logger.error("Nirvana Bridge error: %s", e)
            return False

    def find_existing_task(self, title: str) -> Optional[dict]:
        try:
            resp = requests.get(
                f"{self.bridge_url}/api/tasks",
                headers=self.headers,
                timeout=10,
            )
            if resp.status_code == 200:
                tasks = resp.json().get("tasks", [])
                for t in tasks:
                    if t.get("title", "").lower().strip() == title.lower().strip():
                        return t
            return None
        except:
            return None

    def health_check(self) -> bool:
        try:
            resp = requests.get(f"{self.bridge_url}/health", timeout=5)
            return resp.status_code == 200
        except:
            return False
