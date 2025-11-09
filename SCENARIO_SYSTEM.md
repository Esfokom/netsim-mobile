# Scenario System Implementation

## Overview
This implementation provides a comprehensive two-mode system for creating and playing network scenarios in the NetSim Mobile app.

## Features Implemented

### 1. Data Models 
- **ScenarioCondition** (`scenario_condition.dart`)
  - Supports two types: `Connectivity` and `PropertyCheck`
  - Connectivity checks: PING, HTTP, DNS_LOOKUP protocols
  - Property checks: Supports EQUALS, NOT_EQUALS, CONTAINS operators
  
- **NetworkScenario** (`network_scenario.dart`)
  - Complete scenario metadata (title, description, difficulty)
  - Initial device states and links
  - Player settings (available tools, editable devices)
  - Success conditions list
  - JSON import/export support

### 2. Two-Mode System

#### Edit Mode
- Full control over canvas devices
- **Bottom Panel with 3 Tabs:**
  1. **Devices Tab**: Device palette to add new devices
  2. **Properties Tab**: Contextual editor
     - Shows scenario metadata when nothing is selected
     - Shows device properties when a device is selected
  3. **Conditions Tab**: Success conditions editor
     - Add/edit/remove conditions
     - Visual condition cards
     - Dialog-based condition creation

- **Top Header:**
  - Mode indicator (EDIT MODE)
  - Scenario title
  - Save button
  - Export JSON button
  - Run simulation button
  - Exit button

#### Simulation Mode
- **Restricted Interaction:**
  - Canvas is in simulation mode
  - Devices can be modified according to player settings
  - Bottom panel is hidden (simulation-only UI)

- **Top Header:**
  - Mode indicator (SIMULATION MODE)
  - Scenario title and description
  - Back to Edit button

- **Bottom Action:**
  - "Check My Solution" button
  - Validates all success conditions
  - Shows results dialog with pass/fail for each condition

### 3. State Management (Riverpod 3.0)
- **ScenarioProvider** (`scenario_provider.dart`)
  - Manages scenario state
  - Handles mode switching
  - Snapshots canvas state
  - Checks success conditions
  - Import/export JSON

### 4. UI Components

#### ScenarioBottomPanel
- Three-tab interface
- Clean tab switching
- Responsive design

#### ContextualEditor
- Dual-mode display:
  - Scenario settings (when nothing selected)
  - Device properties (when device selected)
- Real-time updates via Riverpod

#### ConditionsEditor
- List of all conditions
- Add condition dialog
- Type-specific forms
- Delete conditions

### 5. Integration Points

#### Canvas Integration
- Devices now select in both Canvas and Scenario providers
- Device selection triggers contextual editor update
- Canvas state is snapshotted before simulation

#### Device Widget Integration
- Clicking a device selects it for editing
- Device properties are displayed in contextual editor
- Seamless integration with existing canvas functionality

## JSON Schema

The system generates standardized JSON following this structure:

```json
{
  "scenarioID": "unique-id",
  "title": "Scenario Title",
  "description": "Scenario description",
  "difficulty": "Easy|Medium|Hard",
  "initialDeviceStates": [
    {
      "id": "device-id",
      "name": "Device Name",
      "type": "router|switch|server|...",
      "position": {"x": 100, "y": 200},
      "status": "online|offline|warning|error"
    }
  ],
  "initialLinks": [
    {
      "id": "link-id",
      "fromDeviceId": "device-1",
      "toDeviceId": "device-2"
    }
  ],
  "playerSettings": {
    "availableTools": ["ping", "ipconfig"],
    "editableDevices": []
  },
  "successConditions": [
    {
      "id": "condition-id",
      "description": "PC-01 must ping server",
      "type": "CONNECTIVITY",
      "protocol": "PING",
      "sourceDeviceID": "PC-01",
      "targetAddress": "192.168.1.1"
    }
  ],
  "createdAt": "2025-11-09T...",
  "lastModified": "2025-11-09T..."
}
```

## Usage Flow

### Creating a Scenario
1. Open Game View (Edit Mode)
2. Add devices from Device Palette
3. Position and connect devices on canvas
4. Click devices to edit properties in Properties tab
5. Switch to Conditions tab to add success conditions
6. Save or export scenario

### Running a Simulation
1. Click "Run" button in Edit Mode
2. Canvas state is snapshotted
3. Mode switches to Simulation
4. Player can interact with devices (based on settings)
5. Click "Check My Solution" to validate
6. View pass/fail results
7. Return to Edit Mode to make changes

## Future Enhancements
- Full device property editing (IP addresses, MAC addresses, etc.)
- Simulation engine integration for connectivity checks
- Scenario library/storage
- Leaderboard integration
- Advanced property checks
- Device terminals in simulation mode
- Hints system
- Multi-step scenarios

## Files Created
1. `lib/features/scenarios/data/models/scenario_condition.dart`
2. `lib/features/scenarios/data/models/network_scenario.dart`
3. `lib/features/scenarios/presentation/providers/scenario_provider.dart`
4. `lib/features/scenarios/presentation/widgets/scenario_bottom_panel.dart`
5. `lib/features/scenarios/presentation/widgets/contextual_editor.dart`
6. `lib/features/scenarios/presentation/widgets/conditions_editor.dart`

## Files Modified
1. `lib/features/scenarios/presentation/game_view.dart` - Complete rewrite with two modes
2. `lib/features/canvas/presentation/widgets/canvas_device_widget.dart` - Added scenario integration

