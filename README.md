# OneWheel App

A Flutter application for connecting to and monitoring OneWheel devices via BLE.

## Features

- **Comprehensive OneWheel Support**: Compatible with XR, Pint, GT, and the newer GT-S models
- **Enhanced Authentication**: Robust authentication with the latest GT-S compatibility
- **Real-time Data Monitoring**: View battery levels, temperature, speed, and more
- **Ride Tracking**: Log and analyze your rides
- **Route Mapping**: View your routes on a map

## OneWheel Model Compatibility

| Model | Status | Authentication Method |
|-------|--------|----------------------|
| XR    | ✅ Fully Supported | Classic Authentication |
| Pint  | ✅ Fully Supported | Classic Authentication |
| GT    | ✅ Fully Supported | Enhanced Authentication |
| GT-S  | ✅ Fully Supported | Multiple Authentication Methods |

## GT-S Support

The app now features improved compatibility with the newer GT-S models (2024-2025) with:

- Extended connection timeouts
- Multiple authentication strategies
- Enhanced challenge-response handling
- Special GT-S wakeup sequences
- Improved reliability and error handling

### GT-S Authentication Implementation

The app uses a multi-strategy approach to authenticate with GT-S boards:

1. **Direct Unlock Sequence** - Tries GT-S specific unlock commands first
2. **Modified Challenge-Response** - Uses specialized GT-S challenge-response algorithm if direct unlock fails
3. **Board Wakeup** - Attempts to "wake up" GT-S boards by reading multiple characteristics
4. **Adaptive Timeouts** - Uses longer timeouts and connection parameters for GT-S boards
5. **Error Recovery** - Implements robust error handling and reconnection strategies

## Implementation Details

### GT-S Authentication Flow

The GT-S authentication process follows these steps:

1. **Initial Connection** - Establishes BLE connection with extended timeouts for GT-S models
2. **Service Discovery** - Discovers all available BLE services and characteristics
3. **Authentication Sequence**:
   - **Direct Unlock** - Attempts to send known GT-S unlock commands
   - **Challenge-Response** - If direct unlock fails, uses the challenge-response protocol
   - **MD5 Hash Generation** - Creates a response hash using the board's challenge and a known key
   - **Verification** - Confirms authentication by reading protected characteristics

### Data Model

The `OnewheelData` class captures all telemetry from the board:

- Battery information (percentage, voltage)
- Motion data (pitch, roll, yaw)
- Performance metrics (speed, RPM)
- Temperature and other diagnostics

### Connection Reliability

The app implements several reliability features:

- Connection watchdog to detect and reconnect dropped connections
- Heartbeat mechanism to keep the board unlocked
- Multiple retry strategies with progressive backoff
- Error recovery for intermittent BLE issues

## Development Notes

### Code Quality

- The codebase follows Flutter best practices and uses a provider-based architecture
- Some debug print statements remain in the code for development purposes
- Production release should use proper logging framework instead of direct print statements
- Use `flutter run --release` for performance testing

### Structure and Organization

- `lib/models/onewheel_data.dart` - Data model for OneWheel telemetry
- `lib/services/onewheel_ble_service.dart` - Core BLE communication service
- `lib/providers/` - State management for the application
- `lib/screens/` - UI screens and components
- `lib/utils/` - Helper functions and utilities

### Recent Fixes (July 2025)

- Fixed missing `OnewheelData` class implementation
- Improved error handling in BLE connection lifecycle
- Added proper method implementation order to avoid forward references
- Fixed connection watchdog implementation
- Enhanced the challenge-response mechanism for GT-S models
