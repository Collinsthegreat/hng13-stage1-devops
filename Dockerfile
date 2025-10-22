# Use an official lightweight Python image
FROM python:3.10-slim

# Set working directory inside container
WORKDIR /app

# Copy all project files into the container
COPY . .

# Install dependencies if requirements.txt exists
RUN if [ -f requirements.txt ]; then pip install -r requirements.txt; fi

# Expose the internal app port (matches the one you entered earlier)
EXPOSE 8000

# Run a simple web server (replace this with your app command if you have one)
CMD ["python3", "-m", "http.server", "8000"]
