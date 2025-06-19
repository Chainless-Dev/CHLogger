# CHLogger Swift Package

A comprehensive logging framework for iOS apps that combines native os.log with file-based logging.

## Features

- ✅ Uses native OS Logger for system integration
- ✅ Global logging functions (`log.info`, `log.error`, etc.)
- ✅ Automatic class name detection and logging
- ✅ Emoji prefixes for different log levels
- ✅ File-based logging for user sharing
- ✅ Thread-safe logging operations
- ✅ Easy log file sharing functionality

## Installation

Add this package to your project using Swift Package Manager:

```
https://github.com/yourusername/CHLogger
```

## Usage

### Basic Logging
```swift
import CHLogger

class MyViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        log.info("View did load successfully")
        log.warning("This is a warning message")
        log.error("Something went wrong")
    }
}
```

### Log File Sharing
```swift
class SettingsViewController: UIViewController {
    @IBAction func shareLogsButtonTapped(_ sender: UIButton) {
        CHLogger.shared.shareLogFile(from: self)
    }
    
    func getRecentLogs() {
        let recentEntries = CHLogger.shared.getFormattedLogEntries(limit: 100)
        // Display in table view or text view
    }
}
```

### Log File Management
```swift
// Get log file contents
let logContents = CHLogger.shared.getLogFileContents()

// Clear log file
CHLogger.shared.clearLogFile()

// Get log file size
let fileSize = CHLogger.shared.getLogFileSize()

// Get log file URL for sharing
let fileURL = CHLogger.shared.getLogFileURL()
```

## Log Output Format

Console/System Log:
```
💙 [MyViewController] View did load successfully
⚠️ [NetworkManager] Connection timeout occurred
❤️ [DataManager] Failed to save user data
```

Log File:
```
[2024-06-19 14:30:15.123] INFO 💙 [MyViewController] View did load successfully
[2024-06-19 14:30:16.456] WARNING ⚠️ [NetworkManager] Connection timeout occurred
[2024-06-19 14:30:17.789] ERROR ❤️ [DataManager] Failed to save user data
```

## Log Levels

- 🐛 **Debug**: Development debugging information
- 💙 **Info**: General information messages
- ⚠️ **Warning**: Warning conditions
- ❤️ **Error**: Error conditions
- 💀 **Critical**: Critical error conditions
