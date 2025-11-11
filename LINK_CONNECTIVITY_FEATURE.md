# Link/Cable Connectivity Feature

## Overview
Added support for checking if a cable/link exists between two devices as a connectivity condition in scenarios.

## Changes Made

### 1. Schema Updates (`scenario_condition.dart`)

#### Added New Protocol
- Added `link` to the `ConnectivityProtocol` enum
- Updated the enum display name extension to show "Link/Cable"
- Updated the `fromJson` method to handle the `link` protocol type

```dart
enum ConnectivityProtocol { ping, http, dnsLookup, link }
```

**Note:** The schema already supported both `sourceDeviceID` and `targetDeviceID` fields, so no schema changes were needed for storing the device references.

### 2. UI Updates (`conditions_editor.dart`)

#### Conditional Field Display
Modified `_buildConnectivityFields` to show different fields based on the selected protocol:
- **For `link` protocol**: Shows a target device selector (dropdown)
- **For other protocols** (ping, http, dnsLookup): Shows a target address text field

The target device selector:
- Filters out the source device from the options (can't link a device to itself)
- Shows device name, ID, and type
- Uses the same UI pattern as the source device selector

#### Save Logic Update
Updated `_saveCondition` to handle two different validation and save paths:
- **Link protocol**: Validates that both source and target devices are selected, saves `targetDeviceID`
- **Other protocols**: Validates source device and target address, saves `targetAddress`

### 3. Condition Evaluation (`scenario_provider.dart`)

#### Link Connectivity Check
Added implementation in `checkSuccessConditions` method to evaluate link connectivity:

```dart
if (condition.protocol == ConnectivityProtocol.link) {
  // Check if a link exists between source and target devices
  final linkExists = links.any(
    (link) =>
        (link.fromDeviceId == condition.sourceDeviceID &&
            link.toDeviceId == condition.targetDeviceID) ||
        (link.fromDeviceId == condition.targetDeviceID &&
            link.toDeviceId == condition.sourceDeviceID),
  );
  passed = linkExists;
}
```

The check is **bidirectional** - it passes if there's a link from source to target OR from target to source.

## Usage

### Creating a Link Condition

1. Open the conditions editor in the contextual editor
2. Select "Connectivity" as the condition type
3. Select "Link/Cable" as the protocol
4. Select a source device
5. Select a target device
6. Add a description (e.g., "Router 1 must be connected to Switch 1")
7. Save the condition

### How It Works

When the scenario is running in simulation mode:
- The condition checker looks at `simulationLinks` (the current state of links)
- It checks if there's a link connecting the two specified devices
- The check is bidirectional (either direction counts as connected)
- The condition passes if the link exists, fails otherwise

## JSON Format

Example condition in JSON:

```json
{
  "id": "1234567890",
  "description": "Router must be connected to Switch",
  "type": "CONNECTIVITY",
  "protocol": "LINK",
  "sourceDeviceID": "device-1",
  "targetDeviceID": "device-2"
}
```

## Testing

To test this feature:
1. Create a scenario with devices
2. Add a link connectivity condition
3. Run the scenario in simulation mode
4. Add/remove the link between the specified devices
5. Verify that the success screen appears when the link exists

## Future Enhancements

- Add option for checking "no link exists" (inverse condition)
- Support checking for specific link properties (e.g., bandwidth, status)
- Visual feedback in the UI when a link condition is being checked

