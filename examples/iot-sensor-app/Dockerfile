FROM python:3.11-slim

LABEL maintainer="IoT Fleet Management"
LABEL description="IoT Sensor Simulator Application"

WORKDIR /app

# Install MQTT client library
RUN pip install --no-cache-dir paho-mqtt

# Copy application
COPY app.py .

# Make executable
RUN chmod +x app.py

# Run application
CMD ["python3", "app.py"]
