from dataclasses import dataclass, field
from typing import List, Optional, Dict, Any
import numpy as np

@dataclass
class IndexedScreenshot:
    id: str
    user_id: str
    file_path: str
    category: str
    extracted_text: str
    summary: str
    tags: List[str]
    embedding: Optional[List[float]] = None

@dataclass
class SearchHit:
    screenshot: IndexedScreenshot
    score: float
    match_type: str

class HybridSearchEngine:
    """Hybrid search engine combining lexical text matching with vector cosine similarity."""

    def __init__(self):
        self._index: Dict[str, IndexedScreenshot] = {}
        self._seed_default_data()

    def _seed_default_data(self):
        seeds = [
            IndexedScreenshot(
                id="sc-101",
                user_id="demo-user",
                file_path="assets/samples/receipt_starbucks.png",
                category="receipt",
                extracted_text="Starbucks Coffee Order #1042 1x Iced Oat Latte $5.75 1x Almond Croissant $4.25 Total $10.00 Card *1234 Apple Pay",
                summary="Coffee receipt for $10.00 via Apple Pay",
                tags=["coffee", "starbucks", "receipt", "breakfast"],
            ),
            IndexedScreenshot(
                id="sc-102",
                user_id="demo-user",
                file_path="assets/samples/code_snippet.png",
                category="code",
                extracted_text="func handleStream(ctx context.Context, ch <-chan Event) error { for event := range ch { log.Printf('Processed event %s', event.ID) } return nil }",
                summary="Go concurrent event channel handler function",
                tags=["golang", "concurrency", "channels", "code"],
            ),
            IndexedScreenshot(
                id="sc-103",
                user_id="demo-user",
                file_path="assets/samples/flight_booking.png",
                category="document",
                extracted_text="INDIGO FLIGHT 6E-204 DELHI (DEL) -> BANGALORE (BLR) Gate 14B Seat 12F PNR: WXYZ89 Boarding: 16:45",
                summary="Indigo flight boarding pass DEL to BLR PNR WXYZ89",
                tags=["flight", "travel", "indigo", "boarding pass"],
            ),
            IndexedScreenshot(
                id="sc-104",
                user_id="demo-user",
                file_path="assets/samples/chat_address.png",
                category="chat",
                extracted_text="Alex: Hey! Send me the address for tonight Sam: 42 Silicon Lane, Sector 5, Bengaluru, Karnataka 560102 Alex: Got it, see you at 8!",
                summary="Chat message with Bangalore residential address",
                tags=["address", "chat", "alex", "bengaluru"],
            ),
            IndexedScreenshot(
                id="sc-105",
                user_id="demo-user",
                file_path="assets/samples/meme_docker.png",
                category="meme",
                extracted_text="Works on my machine! Then we will ship your machine. And that is how Docker was born.",
                summary="DevOps joke about Docker birth and shipping machine",
                tags=["docker", "meme", "devops", "humor"],
            ),
        ]
        for s in seeds:
            self._index[s.id] = s

    def add_screenshot(self, screenshot: IndexedScreenshot):
        self._index[screenshot.id] = screenshot

    def search(
        self,
        query: str,
        category: Optional[str] = None,
        query_vector: Optional[List[float]] = None,
        limit: int = 30
    ) -> List[SearchHit]:
        q_tokens = query.lower().split()
        results: List[SearchHit] = []

        for item in self._index.values():
            if category and item.category.lower() != category.lower():
                continue

            text_score = 0.0
            searchable_text = f"{item.extracted_text} {item.summary} {' '.join(item.tags)}".lower()

            if not q_tokens:
                text_score = 0.5
            else:
                matches = sum(1 for token in q_tokens if token in searchable_text)
                if matches > 0:
                    text_score = matches / len(q_tokens)
                    if query.lower() in searchable_text:
                        text_score = min(1.0, text_score + 0.3)

            vec_score = 0.0
            if query_vector and item.embedding:
                dot = np.dot(query_vector, item.embedding)
                vec_score = float(max(0.0, min(1.0, dot)))

            # Fusion scoring
            if vec_score > 0 and text_score > 0:
                final_score = round(0.5 * text_score + 0.5 * vec_score, 4)
                match_type = "hybrid"
            elif text_score > 0:
                final_score = round(text_score, 4)
                match_type = "text_exact" if final_score >= 0.8 else "text_keyword"
            elif vec_score > 0:
                final_score = round(vec_score, 4)
                match_type = "semantic"
            else:
                continue

            results.append(SearchHit(screenshot=item, score=final_score, match_type=match_type))

        results.sort(key=lambda h: h.score, reverse=True)
        return results[:limit]

search_engine = HybridSearchEngine()
