FROM python:3.12.4-slim

# Copy the poetry files
RUN pip install poetry==2.0.1
COPY poetry.lock .
COPY pyproject.toml .

# Install from poetry
RUN poetry config virtualenvs.create false
RUN poetry install --no-root

# Environment variable
ENV LOGGER_LEVEL=INFO

# Copy the main app
COPY . /app

# Set the working directory
WORKDIR /app

# Expose the port that the app will run on
EXPOSE 8080

# Starting app
ENTRYPOINT ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
