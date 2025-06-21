# CHLogger Swift Package

A comprehensive, secure logging framework for Swift applications that combines native os.log with file-based logging and automatic PII redaction.

## Features

- ✅ **Native OS Integration**: Uses native OS Logger for system integration and Console.app visibility
- ✅ **Global Logging Interface**: Simple global functions (`log.info`, `log.error`, etc.)
- ✅ **Automatic Class Detection**: Automatically extracts and logs the calling class name
- ✅ **Visual Log Levels**: Emoji prefixes for easy log level identification
- ✅ **Secure File Logging**: File-based logging with automatic PII redaction
- ✅ **Thread-Safe Operations**: All logging operations are thread-safe
- ✅ **Batched Writing**: Efficient batched file writing with configurable buffer size
- ✅ **Log File Rotation**: Automatic file rotation when size limits are exceeded
- ✅ **Structured Logging**: Support for metadata and key-value pairs
- ✅ **Stack Trace Capture**: Automatic stack traces for errors and critical logs
- ✅ **PII Protection**: Comprehensive automatic redaction of sensitive data
- ✅ **Explicit Redaction**: Fine-grained control over what gets redacted
- ✅ **Log Level Filtering**: Configurable minimum log levels
- ✅ **Easy Sharing**: Built-in log file sharing functionality

## Installation

Add this package to your project using Swift Package Manager:

```
https://github.com/alikhanmussabekov/CHLogger
```

### Platform Support

- iOS 14.0+
- macOS 11.0+
- watchOS 7.0+
- tvOS 14.0+
- visionOS 1.0+

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
        log.debug("Debug information")
        log.critical("Critical system error")
    }
}
```

### Structured Logging with Metadata

```swift
let metadata = [
    "userId": "12345",
    "endpoint": "/api/users",
    "duration": "150ms",
    "statusCode": "200"
]

log.info("API call completed", metadata: metadata)
```

### Error Logging with Stack Traces

```swift
// Automatic stack trace for critical logs
log.critical("Database connection failed")

// Optional stack trace for errors
log.error("User validation failed", includeStackTrace: true)
```

### Secure Logging with PII Redaction

#### Explicit Redaction (Recommended)

```swift
let email = "john.doe@example.com"
let password = "secret123"
let apiKey = "sk_live_abc123def456"

// Using predefined redaction types
log.info("User login: email=\(Redacted.email(email)), password=\(Redacted.password(password))")

// Using custom redaction
log.info("API call with key: \(redact(apiKey, as: "[HIDDEN_KEY]"))")

// Multiple redaction types
log.info("Payment: card=\(Redacted.creditCard("4532-1234-5678-9012")), phone=\(Redacted.phone("555-123-4567"))")
```

#### Available Redaction Types

```swift
Redacted.email("user@example.com")        // → [REDACTED_EMAIL]
Redacted.password("secret123")            // → [REDACTED_PASSWORD]
Redacted.creditCard("4532-1234-5678-9012") // → [REDACTED_CARD]
Redacted.apiKey("sk_live_abc123")         // → [REDACTED_API_KEY]
Redacted.phone("555-123-4567")            // → [REDACTED_PHONE]

// Custom redaction
redact("sensitive_data", as: "[CUSTOM_PLACEHOLDER]")
```

#### Automatic PII Redaction

CHLogger automatically redacts common PII patterns in log files:

- Email addresses → `[REDACTED_EMAIL]`
- Credit card numbers → `[REDACTED_CARD]`
- Phone numbers → `[REDACTED_PHONE]`
- Social Security Numbers → `[REDACTED_SSN]`
- Passwords (detected by keywords) → `[REDACTED_PASSWORD]`
- API keys (detected by keywords) → `[REDACTED_API_KEY]`
- IP addresses → `[REDACTED_IP]`

### Log Level Configuration

```swift
// Set minimum log level (useful for production)
log.setMinimumLogLevel(.warning) // Only warning, error, and critical logs will be recorded

// Get current minimum level
let currentLevel = log.getMinimumLogLevel()

// Default levels:
// DEBUG builds: .debug (all logs)
// RELEASE builds: .info (info and above)
```

### Log File Management

```swift
// Get log file contents
let logContents = log.getLogFileContents()

// Get formatted log entries for UI display
let recentEntries = log.getFormattedLogEntries(limit: 100)

// Clear all log files
log.clearLogFile()

// Get log file size
let fileSize = log.getLogFileSize()

// Get log file URL for sharing
let fileURL = log.getLogFileURL()

// Get all log file URLs (including rotated files)
let allFileURLs = log.getAllLogFileURLs()

// Force flush buffered logs to disk
log.forceFlushLogs()
```

### Log File Sharing

```swift
class SettingsViewController: UIViewController {
    @IBAction func shareLogsButtonTapped(_ sender: UIButton) {
        let fileURL = log.getLogFileURL()
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        present(activityVC, animated: true)
    }
}
```

## Security Features

### Dual Logging Approach

CHLogger uses a unique dual-logging approach for security:

- **Console/System Logs**: Show full messages for debugging (visible in Xcode console and Console.app)
- **File Logs**: Automatically redact sensitive information for safe sharing

### Example Security Behavior

```swift
let email = "john@example.com"
log.info("User logged in: \(Redacted.email(email))")

// Console output: "💙 [MyClass] User logged in: john@example.com"
// File output:    "💙 [MyClass] User logged in: [REDACTED_EMAIL]"
```

This ensures developers can see full information during debugging while protecting user privacy in shareable log files.

## Log Output Format

### Console/System Log Output
```
💙 [MyViewController] View did load successfully
⚠️ [NetworkManager] Connection timeout occurred | endpoint=/api/users, duration=5000ms
❤️ [DataManager] Failed to save user data
💀 [DatabaseManager] Critical database error
```

### File Log Output
```
[2024-06-19 14:30:15.123] 1 💙 [MyViewController] View did load successfully
[2024-06-19 14:30:16.456] 2 ⚠️ [NetworkManager] Connection timeout occurred | endpoint=/api/users, duration=5000ms
[2024-06-19 14:30:17.789] 3 ❤️ [DataManager] Failed to save user data
[2024-06-19 14:30:18.012] 4 💀 [DatabaseManager] Critical database error
```

## Log Levels

| Level | Value | Emoji | Description | Stack Trace |
|-------|-------|-------|-------------|-------------|
| Debug | 0 | 🐛 | Development debugging information | No |
| Info | 1 | 💙 | General information messages | No |
| Warning | 2 | ⚠️ | Warning conditions | No |
| Error | 3 | ❤️ | Error conditions | Optional |
| Critical | 4 | 💀 | Critical error conditions | Automatic |

## Performance Features

- **Asynchronous Logging**: All file operations happen on background queues
- **Batched Writing**: Logs are buffered and written in batches for efficiency
- **Automatic Flushing**: Buffers are automatically flushed every 5 seconds or when buffer is full
- **File Rotation**: Automatic rotation when files exceed 5MB (configurable)
- **Thread Safety**: All operations are thread-safe using dedicated queues

## Advanced Configuration

### File Rotation Settings

The logger automatically rotates files when they exceed 5MB and maintains up to 3 log files:
- `app_logs.txt` (current)
- `app_logs_1.txt` (previous)
- `app_logs_2.txt` (oldest)

### Buffer Configuration

- **Buffer Size**: 25 log entries (configurable)
- **Flush Interval**: 5 seconds maximum
- **Force Flush**: Available via `log.forceFlushLogs()`

## Testing

The package includes comprehensive tests covering:

- ✅ Core logging functionality
- ✅ Security and redaction features
- ✅ File management operations
- ✅ Performance characteristics
- ✅ Log level filtering
- ✅ Structured logging
- ✅ Stack trace capture

Run tests with:
```bash
swift test
```

## Requirements

- Swift 6.1+
- Xcode 16.0+
