import Testing
import Foundation
@testable import CHLogger

// MARK: - Core Functionality Tests
@Suite("CHLogger Core Functionality")
struct CHLoggerCoreTests {

    @Test("Logger initialization and basic setup")
    func testLoggerInitialization() {
        let fileURL = log.getLogFileURL()
        #expect(FileManager.default.fileExists(atPath: fileURL.path.replacingOccurrences(of: "/app_logs.txt", with: "")))
    }

    @Test("Global logging functions work correctly")
    func testGlobalLogging() async throws {
        // Clear log file before test
        log.clearLogFile()

        // Log different levels
        log.info("Test info message")
        log.error("Test error message")
        log.debug("Test debug message")
        log.warning("Test warning message")

        // Force flush to ensure logs are written
        log.forceFlushLogs()

        // Wait a bit for async operations
        try await Task.sleep(for: .milliseconds(300))

        let logContents = log.getLogFileContents()
        #expect(logContents != nil, "Log file should contain content")

        if let contents = logContents {
            #expect(contents.contains("💙 [CHLoggerTests:"))
            #expect(contents.contains("❤️ [CHLoggerTests:"))
            #expect(contents.contains("🐛 [CHLoggerTests:"))
            #expect(contents.contains("⚠️ [CHLoggerTests:"))
            #expect(contents.contains("Test info message"))
            #expect(contents.contains("Test error message"))
            #expect(contents.contains("Test debug message"))
            #expect(contents.contains("Test warning message"))
        }
    }

    @Test("Log levels have correct properties")
    func testLogLevelProperties() {
        #expect(LogLevel.debug.rawValue == 0)
        #expect(LogLevel.info.rawValue == 1)
        #expect(LogLevel.warning.rawValue == 2)
        #expect(LogLevel.error.rawValue == 3)
        #expect(LogLevel.critical.rawValue == 4)

        #expect(LogLevel.debug.emoji == "🐛")
        #expect(LogLevel.info.emoji == "💙")
        #expect(LogLevel.warning.emoji == "⚠️")
        #expect(LogLevel.error.emoji == "❤️")
        #expect(LogLevel.critical.emoji == "💀")
    }

    @Test("Minimum log level getter and setter")
    func testMinimumLogLevelConfiguration() {
        let originalLevel = log.getMinimumLogLevel()

        log.setMinimumLogLevel(.warning)
        #expect(log.getMinimumLogLevel() == .warning)

        log.setMinimumLogLevel(.error)
        #expect(log.getMinimumLogLevel() == .error)

        // Restore original level
        log.setMinimumLogLevel(originalLevel)
    }

    @Test("Log level filtering works in production")
    func testLogLevelFiltering() async throws {
        log.clearLogFile()

        // Set minimum level to warning
        log.setMinimumLogLevel(.warning)

        log.debug("This should not appear")
        log.info("This should not appear")
        log.warning("This should appear")
        log.error("This should appear")

        log.forceFlushLogs()
        try await Task.sleep(for: .milliseconds(200))

        let logContents = log.getLogFileContents()
        #expect(logContents != nil)

        if let contents = logContents {
            #expect(!contents.contains("This should not appear"))
            #expect(contents.contains("This should appear"))
            #expect(contents.contains("⚠️ [CHLoggerTests:"))
            #expect(contents.contains("❤️ [CHLoggerTests:"))
        }

        // Reset to debug level for other tests
        log.setMinimumLogLevel(.debug)
    }

    @Test("Structured logging with metadata")
    func testStructuredLogging() async throws {
        log.clearLogFile()

        let metadata = [
            "userId": "12345",
            "endpoint": "/api/users",
            "duration": "150ms"
        ]

        log.info("API call completed", metadata: metadata)

        log.forceFlushLogs()
        try await Task.sleep(for: .milliseconds(200))

        let logContents = log.getLogFileContents()
        #expect(logContents != nil)

        if let contents = logContents {
            #expect(contents.contains("API call completed"))
            #expect(contents.contains("userId=12345"))
            #expect(contents.contains("endpoint=/api/users"))
            #expect(contents.contains("duration=150ms"))
        }
    }

    @Test("Stack trace capture for errors")
    func testStackTraceCapture() async throws {
        log.clearLogFile()

        log.error("Critical error occurred", includeStackTrace: true)
        log.critical("System failure") // Stack trace auto-included

        log.forceFlushLogs()
        try await Task.sleep(for: .milliseconds(200))

        let logContents = log.getLogFileContents()
        #expect(logContents != nil)

        if let contents = logContents {
            #expect(contents.contains("Critical error occurred"))
            #expect(contents.contains("System failure"))
            // Check for stack trace indicators
            #expect(contents.contains("CHLoggerTests") || contents.contains("testStackTraceCapture"))
        }
    }
}

// MARK: - Security and Redaction Tests
@Suite("CHLogger Security and Redaction")
struct CHLoggerSecurityTests {

    @Test("Explicit redaction works correctly")
    func testExplicitRedaction() async throws {
        log.clearLogFile()

        let email = "john.doe@example.com"
        let password = "secret123"
        let apiKey = "sk_live_abc123def456"

        // Log with explicit redaction
        log.info("User login: email=\(Redacted.email(email)), password=\(Redacted.password(password))")
        log.info("API call with key: \(redact(apiKey, as: "[REDACTED_API_KEY]"))")

        log.forceFlushLogs()
        try await Task.sleep(for: .milliseconds(200))

        let logContents = log.getLogFileContents()
        #expect(logContents != nil, "Log file should contain content")

        if let contents = logContents {
            // File should contain redacted versions
            #expect(contents.contains("[REDACTED_EMAIL]"), "File should contain redacted email")
            #expect(contents.contains("[REDACTED_PASSWORD]"), "File should contain redacted password")
            #expect(contents.contains("[REDACTED_API_KEY]"), "File should contain redacted API key")

            // File should NOT contain original values
            #expect(!contents.contains(email), "File should not contain original email")
            #expect(!contents.contains(password), "File should not contain original password")
            #expect(!contents.contains(apiKey), "File should not contain original API key")
        }
    }

    @Test("Console vs File redaction difference")
    func testConsoleVsFileRedaction() async throws {
        log.clearLogFile()

        let sensitiveData = "password123"
        let message = "Login attempt with password: \(redact(sensitiveData, as: "[HIDDEN]"))"

        log.info(message)
        log.forceFlushLogs()
        try await Task.sleep(for: .milliseconds(200))

        let fileContents = log.getLogFileContents()
        #expect(fileContents != nil)

        if let contents = fileContents {
            // File should have redacted version
            #expect(contents.contains("[HIDDEN]"), "File should contain placeholder")
            #expect(!contents.contains("password123"), "File should not contain actual password")

            // Note: We can't easily test console output in unit tests,
            // but the console would show the full message with "password123"
        }
    }

    @Test("No redaction preserves original message")
    func testNoRedaction() async throws {
        log.clearLogFile()

        let normalMessage = "User logged in successfully"
        log.info(normalMessage)

        log.forceFlushLogs()
        try await Task.sleep(for: .milliseconds(200))

        let logContents = log.getLogFileContents()
        #expect(logContents != nil)

        if let contents = logContents {
            #expect(contents.contains(normalMessage), "Should contain original message when no redaction is used")
        }
    }

    @Test("Multiple redaction types in one message")
    func testMultipleRedactionTypes() async throws {
        log.clearLogFile()

        let email = "user@example.com"
        let creditCard = "4532-1234-5678-9012"
        let phone = "555-123-4567"

        log.info("Payment info: email=\(Redacted.email(email)), card=\(Redacted.creditCard(creditCard)), phone=\(Redacted.phone(phone))")

        log.forceFlushLogs()
        try await Task.sleep(for: .milliseconds(200))

        let logContents = log.getLogFileContents()
        #expect(logContents != nil)

        if let contents = logContents {
            // Should contain all redacted placeholders
            #expect(contents.contains("[REDACTED_EMAIL]"))
            #expect(contents.contains("[REDACTED_CARD]"))
            #expect(contents.contains("[REDACTED_PHONE]"))

            // Should not contain original values
            #expect(!contents.contains(email))
            #expect(!contents.contains(creditCard))
            #expect(!contents.contains(phone))
        }
    }

    @Test("Custom redaction placeholder")
    func testCustomRedactionPlaceholder() async throws {
        log.clearLogFile()

        let secretValue = "top_secret_data"
        log.info("Processing: \(redact(secretValue, as: "[CLASSIFIED]"))")

        log.forceFlushLogs()
        try await Task.sleep(for: .milliseconds(200))

        let logContents = log.getLogFileContents()
        #expect(logContents != nil)

        if let contents = logContents {
            #expect(contents.contains("[CLASSIFIED]"), "Should contain custom placeholder")
            #expect(!contents.contains(secretValue), "Should not contain original value")
        }
    }

    @Test("PII redaction comprehensive test")
    func testComprehensivePIIRedaction() async throws {
        log.clearLogFile()

        let sensitiveMessage = """
        User data: email=john.doe@company.com, phone=555-123-4567, 
        ssn=123-45-6789, card=4532123456789012, password=mySecret123,
        api_key=sk_live_abc123def456, ip=10.0.0.1
        """

        log.info(sensitiveMessage)
        log.forceFlushLogs()
        try await Task.sleep(for: .milliseconds(200))

        let contents = log.getLogFileContents()!

        // Verify all sensitive data is redacted
        #expect(contents.contains("[REDACTED_EMAIL]"))
        #expect(contents.contains("[REDACTED_PHONE]"))
        #expect(contents.contains("[REDACTED_SSN]"))
        #expect(contents.contains("[REDACTED_CARD]"))
        #expect(contents.contains("[REDACTED_PASSWORD]"))
        #expect(contents.contains("[REDACTED_API_KEY]"))
        #expect(contents.contains("[REDACTED_IP]"))

        // Verify original sensitive data is not present
        #expect(!contents.contains("john.doe@company.com"))
        #expect(!contents.contains("555-123-4567"))
        #expect(!contents.contains("123-45-6789"))
        #expect(!contents.contains("4532123456789012"))
        #expect(!contents.contains("mySecret123"))
        #expect(!contents.contains("sk_live_abc123def456"))
        #expect(!contents.contains("10.0.0.1"))
    }
}

// MARK: - File Management Tests
@Suite("CHLogger File Management")
struct CHLoggerFileManagementTests {

    @Test("Log file management functions")
    func testLogFileManagement() async throws {
        log.clearLogFile()

        // Initially empty
        #expect(log.getLogFileSize() == 0, "Log file should be empty initially")

        log.info("Test message for file management")
        log.forceFlushLogs()
        try await Task.sleep(for: .milliseconds(200))

        // Should have content now
        #expect(log.getLogFileSize() > 0, "Log file should have content after logging")

        let fileURL = log.getLogFileURL()
        #expect(FileManager.default.fileExists(atPath: fileURL.path), "Log file should exist")

        // Clear and verify
        log.clearLogFile()
        try await Task.sleep(for: .milliseconds(200))

        #expect(log.getLogFileSize() == 0, "Log file should be empty after clearing")
    }

    @Test("Multiple log files handling")
    func testMultipleLogFiles() async throws {
        log.clearLogFile()

        // Create some logs
        for i in 0..<10 {
            log.info("Multi-file test message \(i)")
        }

        log.forceFlushLogs()
        try await Task.sleep(for: .milliseconds(200))

        let allFiles = log.getAllLogFileURLs()
        #expect(allFiles.count >= 1, "Should have at least one log file")

        let contents = log.getLogFileContents()
        #expect(contents != nil, "Should be able to get combined contents")

        if let contents = contents {
            #expect(contents.contains("Multi-file test message 0"))
            #expect(contents.contains("Multi-file test message 9"))
        }
    }

    @Test("File rotation works when size limit exceeded")
    func testFileRotation() async throws {
        log.clearLogFile()

        // Generate enough logs to trigger rotation (simulate large file)
        for i in 0..<1000 {
            log.info("Large log message number \(i) with lots of additional text to make it bigger and exceed the file size limit for testing rotation functionality")
        }

        log.forceFlushLogs()
        try await Task.sleep(for: .milliseconds(500))

        let allLogFiles = log.getAllLogFileURLs()
        #expect(allLogFiles.count >= 1, "Should have at least one log file")

        let totalSize = log.getLogFileSize()
        #expect(totalSize > 0, "Total log size should be greater than 0")
    }

    @Test("Log entry parsing")
    func testLogEntryParsing() async throws {
        log.clearLogFile()

        log.info("Test parsing message")
        log.error("Error parsing message")

        log.forceFlushLogs()
        try await Task.sleep(for: .milliseconds(200))

        let entries = log.getFormattedLogEntries()
        #expect(entries.count >= 2, "Should have at least 2 log entries")

        let infoEntry = entries.first { $0.level == .info }
        let errorEntry = entries.first { $0.level == .error }

        #expect(infoEntry != nil, "Should have info entry")
        #expect(errorEntry != nil, "Should have error entry")

        if let info = infoEntry {
            #expect(info.message.contains("Test parsing message"))
            #expect(info.className == "CHLoggerTests")
            #expect(info.lineNumber != nil, "Line number should be present")
            #expect(info.emoji == "💙")
        }

        if let error = errorEntry {
            #expect(error.message.contains("Error parsing message"))
            #expect(error.level == .error)
            #expect(error.emoji == "❤️")
        }
    }
}

// MARK: - Performance Tests
@Suite("CHLogger Performance")
struct CHLoggerPerformanceTests {

    @Test("Batched writing performance")
    func testBatchedWriting() async throws {
        log.clearLogFile()

        let startTime = Date()

        // Log many messages quickly
        for i in 0..<100 {
            log.info("Performance test message \(i)")
        }

        let loggingTime = Date().timeIntervalSince(startTime)

        // Should complete quickly since it's async
        #expect(loggingTime < 0.1, "Logging should be very fast due to async nature")

        log.forceFlushLogs()
        try await Task.sleep(for: .milliseconds(300))

        let logContents = log.getLogFileContents()
        #expect(logContents != nil)

        if let contents = logContents {
            #expect(contents.contains("Performance test message 0"))
            #expect(contents.contains("Performance test message 99"))
        }
    }
    
    @Test("High volume logging performance")
    func testHighVolumeLogging() async throws {
        log.clearLogFile()

        // Log 1000 messages
        for i in 0..<1000 {
            log.info("High volume message \(i)")
        }

        log.forceFlushLogs()
        try await Task.sleep(for: .milliseconds(1000))

        let contents = log.getLogFileContents()
        #expect(contents != nil)
        #expect(contents!.contains("High volume message 999"))
    }
}
