FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Copy the requirements file
COPY requirements.txt .

# Install the dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application files
COPY src/ ./src/

# Set the environment variable for Python
ENV PYTHONUNBUFFERED=1

# Command to run the application
CMD ["python", "src/main.py"]