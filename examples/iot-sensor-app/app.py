#!/usr/bin/env python3
"""
IoT Sensor Simulator - Example Application

This app simulates an IoT sensor device that:
- Generates random sensor data (temperature, humidity, CPU temp)
- Publishes data to MQTT broker
- Sends telemetry to ThingsBoard

Usage:
  python3 app.py

Environment Variables:
  MQTT_BROKER    - MQTT broker hostname (default: 192.168.1.100)
  MQTT_PORT      - MQTT broker port (default: 1883)
  MQTT_TOPIC     - MQTT topic (default: v1/devices/me/telemetry)
  ACCESS_TOKEN   - ThingsBoard device access token
  INTERVAL       - Publishing interval in seconds (default: 5)
"""

import time
import json
import random
import os
import sys
from datetime import datetime

try:
    import paho.mqtt.client as mqtt
    HAS_MQTT = True
except ImportError:
    HAS_MQTT = False
    print("WARNING: paho-mqtt not installed")
    print("Install with: pip install paho-mqtt")
    print("Will run in simulation mode\n")

# Configuration
MQTT_BROKER = os.getenv('MQTT_BROKER', '192.168.1.100')
MQTT_PORT = int(os.getenv('MQTT_PORT', '1883'))
MQTT_TOPIC = os.getenv('MQTT_TOPIC', 'v1/devices/me/telemetry')
ACCESS_TOKEN = os.getenv('ACCESS_TOKEN', '')
INTERVAL = int(os.getenv('INTERVAL', '5'))

def generate_sensor_data():
    """Generate random sensor data"""
    return {
        "temperature": round(random.uniform(20.0, 30.0), 2),
        "humidity": round(random.uniform(40.0, 80.0), 2),
        "cpu_temp": round(random.uniform(35.0, 55.0), 2),
        "pressure": round(random.uniform(980.0, 1020.0), 2),
        "timestamp": datetime.now().isoformat()
    }

def on_connect(client, userdata, flags, rc):
    """MQTT connection callback"""
    if rc == 0:
        print(f"✓ Connected to MQTT broker at {MQTT_BROKER}:{MQTT_PORT}")
    else:
        print(f"✗ Connection failed with code {rc}")

def on_publish(client, userdata, mid):
    """MQTT publish callback"""
    pass  # Uncomment for debug: print(f"Message {mid} published")

def main():
    print("=" * 50)
    print("IoT Sensor Simulator")
    print("=" * 50)
    print(f"MQTT Broker: {MQTT_BROKER}:{MQTT_PORT}")
    print(f"MQTT Topic:  {MQTT_TOPIC}")
    print(f"Interval:    {INTERVAL} seconds")

    if ACCESS_TOKEN:
        print(f"ThingsBoard: Enabled (token: {ACCESS_TOKEN[:8]}...)")
    else:
        print("ThingsBoard: Disabled (no ACCESS_TOKEN)")

    print("=" * 50)
    print()

    client = None

    if HAS_MQTT:
        # Setup MQTT client
        client = mqtt.Client()

        if ACCESS_TOKEN:
            # Use ThingsBoard authentication
            client.username_pw_set(ACCESS_TOKEN)

        client.on_connect = on_connect
        client.on_publish = on_publish

        try:
            client.connect(MQTT_BROKER, MQTT_PORT, 60)
            client.loop_start()
        except Exception as e:
            print(f"✗ Failed to connect to MQTT broker: {e}")
            print("Running in simulation mode\n")
            client = None

    print("Starting sensor readings... (Ctrl+C to stop)\n")

    message_count = 0

    try:
        while True:
            # Generate sensor data
            data = generate_sensor_data()
            message = json.dumps(data)

            message_count += 1

            if client:
                # Publish to MQTT broker
                result = client.publish(MQTT_TOPIC, message)

                if result.rc == mqtt.MQTT_ERR_SUCCESS:
                    print(f"[{message_count:04d}] ✓ Published: {message}")
                else:
                    print(f"[{message_count:04d}] ✗ Publish failed: {message}")
            else:
                # Simulation mode
                print(f"[{message_count:04d}] ⚙ Simulated: {message}")

            # Wait before next reading
            time.sleep(INTERVAL)

    except KeyboardInterrupt:
        print("\n\nStopping sensor...")

        if client:
            client.loop_stop()
            client.disconnect()

        print(f"Total messages: {message_count}")
        print("Goodbye!\n")
        sys.exit(0)

if __name__ == "__main__":
    main()
