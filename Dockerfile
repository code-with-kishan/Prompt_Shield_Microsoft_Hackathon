# Dockerfile
FROM python:3.12-slim

# Install system dependencies required for compilation and SQLite builds
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set up non-root user for Hugging Face compliance (UID 1000)
RUN useradd -m -u 1000 user
USER user
ENV PATH="/home/user/.local/bin:$PATH"

WORKDIR /home/user/app

# Copy package descriptors first to cache dependencies (ensure user ownership)
COPY --chown=user pyproject.toml README.md ./
COPY --chown=user src/ ./src/

# Install core, ML, and integration dependencies
RUN pip install --no-cache-dir \
    "pydantic>=2.0" \
    "pyyaml>=6.0" \
    "click>=8.0" \
    "regex>=2023.0" \
    "sentence-transformers>=2.0" \
    "chromadb>=0.5" \
    "fastapi>=0.100" \
    "starlette>=0.27" \
    "flask>=2.0" \
    "langchain-core>=0.1" \
    "mcp>=1.0" \
    "openai>=1.0" \
    "anthropic>=0.30" \
    "uvicorn>=0.20"

# Install prompt-shield-ai itself (regular build, not editable)
RUN pip install --no-cache-dir . --no-deps

# Pre-cache the sentence-transformers model during build time to avoid slow cold starts
RUN python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('all-MiniLM-L6-v2')"

# Expose default port for Hugging Face Spaces
ENV PROMPT_SHIELD_PORT=7860
EXPOSE 7860

# Start the API server
CMD ["python", "-m", "prompt_shield.api"]



