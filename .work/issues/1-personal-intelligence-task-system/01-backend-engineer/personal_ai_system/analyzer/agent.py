import json
import requests
import logging
from typing import Optional, List
from .prompts import SYSTEM_PROMPT, USER_PROMPT_TEMPLATE
from .parser import ResponseParser
from .local_analyzer import LocalAnalyzer
from memory.models import Suggestion

logger = logging.getLogger("pits.analyzer")


class AnalyzerAgent:
    def __init__(self, ollama_url: str = "http://localhost:11434", model: str = "llama3"):
        self.ollama_url = ollama_url
        self.model = model
        self.parser = ResponseParser()
        self.local = LocalAnalyzer()

    def analyze(self, text: str, context: Optional[str] = None) -> List[Suggestion]:
        ollama_available = self.health_check()
        if ollama_available:
            prompt = USER_PROMPT_TEMPLATE.format(text=text)
            if context:
                prompt = f"Context from previous entries:\n{context}\n\n---\n\n{prompt}"
            response = self._call_llm(prompt)
            if response:
                suggestions = self.parser.parse(response)
                if suggestions:
                    return suggestions
                logger.info("LLM returned empty, falling back to local analyzer")
            else:
                logger.info("LLM unavailable, falling back to local analyzer")
        else:
            logger.info("Ollama not available, using local rule-based analyzer")

        return self.local.analyze(text)

    def _call_llm(self, prompt: str) -> Optional[str]:
        try:
            payload = {
                "model": self.model,
                "system": SYSTEM_PROMPT,
                "prompt": prompt,
                "stream": False,
                "temperature": 0.1,
                "max_tokens": 2000,
            }
            resp = requests.post(
                f"{self.ollama_url}/api/generate",
                json=payload,
                timeout=60,
            )
            if resp.status_code == 200:
                data = resp.json()
                return data.get("response", "")
            logger.warning(f"Ollama returned status {resp.status_code}")
            return None
        except requests.ConnectionError:
            logger.error("Cannot connect to Ollama at %s", self.ollama_url)
            return None
        except Exception as e:
            logger.error("LLM call failed: %s", e)
            return None

    def health_check(self) -> bool:
        try:
            resp = requests.get(f"{self.ollama_url}/api/tags", timeout=3)
            return resp.status_code == 200
        except:
            return False
