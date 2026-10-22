# ==============================================================================
# Dockerfile for Python Flask Application (Lab 6)
# ==============================================================================
FROM python:3.12-slim

# Prevent Python from buffering stdout/stderr and writing bytecode
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Copy dependency specifications
COPY requirements.txt .

# Install application dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Create and switch to a non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Expose application port
EXPOSE 5000

# Start Flask application
CMD ["python", "app.py"]
