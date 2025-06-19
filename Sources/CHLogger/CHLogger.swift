// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import OSLog

internal final class CHLogger {
    nonisolated(unsafe) internal static let shared = CHLogger()

    private let osLogger: Logger
    private let fileManager = FileManager.default
    private var logFileURL: URL
    private let dateFormatter: DateFormatter
    private let logQueue = DispatchQueue(label: "com.applogger.logging", qos: .utility, attributes: .concurrent)
    private let fileWriteQueue = DispatchQueue(label: "com.applogger.filewrite", qos: .utility)

    // Log level filtering
    private var minimumLogLevel: LogLevel = {
#if DEBUG
        return .debug
#else
        return .info
#endif
    }()

    // File rotation settings
    private let maxFileSize: Int64 = 5 * 1024 * 1024 // 5MB
    private let maxLogFiles = 3

    // Batched writing
    private var logBuffer: [String] = []
    private let bufferSize = 25
    private var lastFlushTime = Date()
    private let maxFlushInterval: TimeInterval = 5.0 // Flush every 5 seconds

    private init() {
        // Initialize OS Logger
        self.osLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app.logger", category: "CHLogger")

        // Setup date formatter
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        self.dateFormatter.timeZone = TimeZone.current

        // Setup log file URL
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.logFileURL = documentsPath.appendingPathComponent("app_logs.txt")

        // Create log file if it doesn't exist
        createLogFileIfNeeded()

        // Setup periodic buffer flush
        setupPeriodicFlush()
    }

    private func createLogFileIfNeeded() {
        if !fileManager.fileExists(atPath: logFileURL.path) {
            fileManager.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
        }
    }

    private func setupPeriodicFlush() {
        Timer.scheduledTimer(withTimeInterval: maxFlushInterval, repeats: true) { [weak self] _ in
            self?.flushBufferIfNeeded()
        }
    }

    // MARK: - Log Level Management
    internal func setMinimumLogLevel(_ level: LogLevel) {
        minimumLogLevel = level
    }

    internal func getMinimumLogLevel() -> LogLevel {
        return minimumLogLevel
    }

    // MARK: - File Rotation
    private func rotateLogFileIfNeeded() {
        guard getLogFileSize() > maxFileSize else { return }

        // Move current log files
        for i in (1..<maxLogFiles).reversed() {
            let currentFile = getLogFileURL(index: i)
            let nextFile = getLogFileURL(index: i + 1)

            if fileManager.fileExists(atPath: currentFile.path) {
                try? fileManager.removeItem(at: nextFile)
                try? fileManager.moveItem(at: currentFile, to: nextFile)
            }
        }

        // Move current log to index 1
        let archiveFile = getLogFileURL(index: 1)
        try? fileManager.removeItem(at: archiveFile)
        try? fileManager.moveItem(at: logFileURL, to: archiveFile)

        // Create new log file
        createLogFileIfNeeded()
    }

    private func getLogFileURL(index: Int = 0) -> URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        if index == 0 {
            return documentsPath.appendingPathComponent("app_logs.txt")
        } else {
            return documentsPath.appendingPathComponent("app_logs_\(index).txt")
        }
    }

    // MARK: - Batched Writing
    private func flushBufferIfNeeded(force: Bool = false) {
        fileWriteQueue.async { [weak self] in
            guard let self = self else { return }

            let shouldFlush = force ||
            self.logBuffer.count >= self.bufferSize ||
            Date().timeIntervalSince(self.lastFlushTime) >= self.maxFlushInterval

            guard shouldFlush && !self.logBuffer.isEmpty else { return }

            let logsToWrite = self.logBuffer.joined()
            self.logBuffer.removeAll()
            self.lastFlushTime = Date()

            self.writeToFile(message: logsToWrite)
            self.rotateLogFileIfNeeded()
        }
    }

    // MARK: - Data Redaction
    private func redactSensitiveData(_ message: String) -> String {
        var redactedMessage = message

        // Redact common sensitive patterns
        let patterns = [
            // Credit card numbers (simplified)
            ("\\b\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}\\b", "[REDACTED_CARD]"),
            // Email addresses
            ("\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}\\b", "[REDACTED_EMAIL]"),
            // Phone numbers (US format)
            ("\\b\\d{3}[-.\\s]?\\d{3}[-.\\s]?\\d{4}\\b", "[REDACTED_PHONE]"),
            // SSN
            ("\\b\\d{3}[-.\\s]?\\d{2}[-.\\s]?\\d{4}\\b", "[REDACTED_SSN]"),
            // Passwords (case insensitive)
            ("(?i)password[\\s:=]+\\S+", "password: [REDACTED_PASSWORD]"),
            // API keys (common patterns)
            ("(?i)(api[_-]?key|token)[\\s:=]+\\S+", "$1: [REDACTED_API_KEY]"),
            // IP addresses
            ("\\b(?:\\d{1,3}\\.){3}\\d{1,3}\\b", "[REDACTED_IP]")
        ]

        for (pattern, replacement) in patterns {
            redactedMessage = redactedMessage.replacingOccurrences(
                of: pattern,
                with: replacement,
                options: .regularExpression
            )
        }

        return redactedMessage
    }

    private func getClassName(from object: Any) -> String {
        let className = String(describing: type(of: object))
        return className
    }

    private func log(level: LogLevel, message: String, className: String, metadata: [String: Any] = [:], includeStackTrace: Bool = false) {
        // Filter logs based on minimum level
        guard level.rawValue >= minimumLogLevel.rawValue else { return }

        // Perform all logging operations on dedicated queue to avoid blocking caller
        logQueue.async { [weak self] in
            guard let self = self else { return }

            let timestamp = self.dateFormatter.string(from: Date())
            let redactedMessage = self.redactSensitiveData(message)

            var formattedMessage = "\(level.emoji) [\(className)] \(redactedMessage)"

            // Add metadata if provided
            if !metadata.isEmpty {
                let metadataString = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
                formattedMessage += " | \(metadataString)"
            }

            // Add stack trace for errors if requested
            var stackTrace = ""
            if includeStackTrace && (level == .error || level == .critical) {
                stackTrace = "\n" + Thread.callStackSymbols.dropFirst(3).prefix(10).joined(separator: "\n")
                formattedMessage += stackTrace
            }

            // Log to OS Logger
            self.osLogger.log(level: level.osLogType, "\(formattedMessage)")

            // Add to buffer for file writing
            let fileLogMessage = "[\(timestamp)] \(level.rawValue) \(formattedMessage)\n"
            self.fileWriteQueue.async {
                self.logBuffer.append(fileLogMessage)
                self.flushBufferIfNeeded()
            }
        }
    }

    private func writeToFile(message: String) {
        guard let data = message.data(using: .utf8) else { return }

        if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            fileHandle.closeFile()
        }
    }
}

// MARK: - Internal Logging Methods
extension CHLogger {
    internal func debug(_ message: String, fromClassName className: String, metadata: [String: Any] = [:]) {
        log(level: .debug, message: message, className: className, metadata: metadata)
    }

    internal func info(_ message: String, fromClassName className: String, metadata: [String: Any] = [:]) {
        log(level: .info, message: message, className: className, metadata: metadata)
    }

    internal func warning(_ message: String, fromClassName className: String, metadata: [String: Any] = [:]) {
        log(level: .warning, message: message, className: className, metadata: metadata)
    }

    internal func error(_ message: String, fromClassName className: String, metadata: [String: Any] = [:], includeStackTrace: Bool = false) {
        log(level: .error, message: message, className: className, metadata: metadata, includeStackTrace: includeStackTrace)
    }

    internal func critical(_ message: String, fromClassName className: String, metadata: [String: Any] = [:], includeStackTrace: Bool = true) {
        log(level: .critical, message: message, className: className, metadata: metadata, includeStackTrace: includeStackTrace)
    }
}

// MARK: - File Management
extension CHLogger {
    internal func getLogFileURL() -> URL {
        return logFileURL
    }

    internal func getAllLogFileURLs() -> [URL] {
        var urls = [logFileURL]
        for i in 1...maxLogFiles {
            let url = getLogFileURL(index: i)
            if fileManager.fileExists(atPath: url.path) {
                urls.append(url)
            }
        }
        return urls
    }

    internal func getLogFileContents() -> String? {
        // Get contents from all log files, newest first
        let allFiles = getAllLogFileURLs()
        let contents = allFiles.compactMap { url in
            try? String(contentsOf: url, encoding: .utf8)
        }.joined(separator: "\n--- Previous Log File ---\n")

        return contents.isEmpty ? nil : contents
    }

    internal func clearLogFile() {
        fileWriteQueue.async { [weak self] in
            guard let self = self else { return }

            // Clear buffer first
            self.logBuffer.removeAll()

            // Clear all log files
            for url in self.getAllLogFileURLs() {
                try? "".write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    internal func getLogFileSize() -> Int64 {
        return getAllLogFileURLs().reduce(0) { total, url in
            guard let attributes = try? fileManager.attributesOfItem(atPath: url.path) else { return total }
            return total + (attributes[.size] as? Int64 ?? 0)
        }
    }

    internal func forceFlushLogs() {
        flushBufferIfNeeded(force: true)
    }
}
