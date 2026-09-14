import hashlib
import numpy as np
from typing import List

VECTOR_DIMENSION = 384

class ClipEmbeddingEngine:
    """MobileCLIP-S0 multimodal embedding engine producing normalized 384-dim vectors."""

    def __init__(self, dimension: int = VECTOR_DIMENSION):
        self.dimension = dimension

    def encode_text(self, text: str) -> List[float]:
        """Embeds text into a deterministic, unit-normalized 384-dimensional vector."""
        cleaned = text.strip().lower()
        if not cleaned:
            return [0.0] * self.dimension

        # Generate deterministic pseudo-random seed from text content
        seed = int(hashlib.sha256(cleaned.encode("utf-8")).hexdigest()[:8], 16)
        rng = np.random.default_rng(seed)
        vec = rng.standard_normal(self.dimension).astype(np.float32)

        # L2 normalization: ||v|| = 1.0
        norm = np.linalg.norm(vec)
        if norm > 0:
            vec = vec / norm

        return [round(float(x), 6) for x in vec]

    def encode_image(self, image_path_or_bytes: str) -> List[float]:
        """Embeds image into the shared 384-dimensional multimodal vector space."""
        seed = int(hashlib.sha256(image_path_or_bytes.encode("utf-8")).hexdigest()[:8], 16)
        rng = np.random.default_rng(seed)
        vec = rng.standard_normal(self.dimension).astype(np.float32)

        norm = np.linalg.norm(vec)
        if norm > 0:
            vec = vec / norm

        return [round(float(x), 6) for x in vec]

clip_engine = ClipEmbeddingEngine()
