# Node-RED Flow Examples

Sample Node-RED flows for IoT automation and integration.

## Available Flows

### 1. MQTT to ThingsBoard (`mqtt-to-thingsboard.json`)

A basic flow that demonstrates:
- Subscribing to MQTT topics
- Parsing JSON sensor data
- Extracting specific values (temperature)
- Displaying on dashboard gauge
- Debug output

**What it does:**
1. Subscribes to `sensor/data` MQTT topic
2. Parses incoming JSON messages
3. Extracts temperature value
4. Displays on dashboard gauge (0-50°C)
5. Logs to debug panel

## How to Import

### Method 1: Import via UI

1. Open Node-RED: `http://YOUR_SERVER_IP:1880`
2. Click menu (☰) → **Import**
3. Click **select a file to import**
4. Choose the JSON file
5. Click **Import**
6. Click **Deploy**

### Method 2: Import via Clipboard

1. Open the JSON file in a text editor
2. Copy all content (Ctrl+A, Ctrl+C)
3. Open Node-RED: `http://YOUR_SERVER_IP:1880`
4. Click menu (☰) → **Import**
5. Paste JSON into text area
6. Click **Import**
7. Click **Deploy**

## Configuration

After importing, you may need to configure:

### MQTT Broker Node

1. Double-click any MQTT node
2. Click pencil icon next to Server
3. Set **Server**: `YOUR_SERVER_IP` (or `mosquitto` if on same Docker network)
4. Set **Port**: `1883`
5. Click **Update**
6. Click **Done**
7. Click **Deploy**

### Dashboard Access

After deploying a flow with dashboard nodes:

- Dashboard UI: `http://YOUR_SERVER_IP:1880/ui`
- Flow Editor: `http://YOUR_SERVER_IP:1880`

## Testing the Flow

### Send Test Data

```bash
# From server or Raspberry Pi
mosquitto_pub -h YOUR_SERVER_IP \
  -t sensor/data \
  -m '{"temperature": 25.5, "humidity": 60}'
```

### Expected Results

1. **Debug Panel**: Shows the full JSON message
2. **Dashboard**: Temperature gauge updates to 25.5
3. **Debug Sidebar**: Message logged with timestamp

## Creating Your Own Flows

### Common Node Types

**Input Nodes:**
- `mqtt in` - Subscribe to MQTT topics
- `http in` - Create HTTP endpoints
- `inject` - Manual or timed triggers

**Function Nodes:**
- `function` - Write JavaScript to transform data
- `change` - Modify message properties
- `switch` - Route based on conditions

**Output Nodes:**
- `mqtt out` - Publish to MQTT
- `http request` - Make HTTP calls
- `debug` - Display in debug panel

**Dashboard Nodes:**
- `ui_gauge` - Display values on gauge
- `ui_chart` - Line/bar charts
- `ui_text` - Display text
- `ui_button` - Interactive buttons

### Example: Temperature Alert Flow

```
[MQTT In] → [Function: Check Temp] → [Switch] → [Email/Notification]
                                         ├─ > 30°C → Send Alert
                                         └─ < 30°C → Do Nothing
```

## Tips

1. **Use Debug Nodes**: Always add debug nodes to troubleshoot
2. **Test Incrementally**: Build flows step-by-step
3. **Name Your Nodes**: Makes flows easier to understand
4. **Use Subflows**: Reuse common patterns
5. **Document Flows**: Use comment nodes

## Resources

- **Node-RED Documentation**: https://nodered.org/docs/
- **Flow Library**: https://flows.nodered.org/
- **Cookbook**: https://cookbook.nodered.org/

## Example Use Cases

1. **Sensor Monitoring**
   - Read MQTT sensor data
   - Display on dashboard
   - Alert on thresholds

2. **Device Control**
   - Button on dashboard
   - Send MQTT command
   - Control relay/LED

3. **Data Logging**
   - Subscribe to telemetry
   - Store in database
   - Generate reports

4. **Integration**
   - MQTT → ThingsBoard
   - MQTT → HTTP API
   - Timer → MQTT command
