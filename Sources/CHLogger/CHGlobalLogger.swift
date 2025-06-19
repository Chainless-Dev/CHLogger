//
//  GlobalLogger.swift
//  CHLogger
//
//  Created by Alikhan Mussabekov on 19.06.2025.
//

import Foundation

// MARK: - Global Log Instance
public let log = GlobalLogger()

public struct GlobalLogger: Sendable {
    public func setMinimumLogLevel(_ level: LogLevel) {
        CHLogger.shared.setMinimumLogLevel(level)
    }

    public func getMinimumLogLevel() -> LogLevel {
        CHLogger.shared.getMinimumLogLevel()
    }

    public func debug(_ message: String, metadata: [String: Any] = [:], file: String = #file) {
        let className = extractClassName(from: file)
        CHLogger.shared.debug(message, fromClassName: className, metadata: metadata)
    }

    public func info(_ message: String, metadata: [String: Any] = [:], file: String = #file) {
        let className = extractClassName(from: file)
        CHLogger.shared.info(message, fromClassName: className, metadata: metadata)
    }

    public func warning(_ message: String, metadata: [String: Any] = [:], file: String = #file) {
        let className = extractClassName(from: file)
        CHLogger.shared.warning(message, fromClassName: className, metadata: metadata)
    }

    public func error(_ message: String, metadata: [String: Any] = [:], includeStackTrace: Bool = false, file: String = #file) {
        let className = extractClassName(from: file)
        CHLogger.shared.error(message, fromClassName: className, metadata: metadata, includeStackTrace: includeStackTrace)
    }

    public func critical(_ message: String, metadata: [String: Any] = [:], includeStackTrace: Bool = true, file: String = #file) {
        let className = extractClassName(from: file)
        CHLogger.shared.critical(message, fromClassName: className, metadata: metadata, includeStackTrace: includeStackTrace)
    }

    private func extractClassName(from filePath: String) -> String {
        let fileName = URL(fileURLWithPath: filePath).lastPathComponent
        return String(fileName.dropLast(6)) // Remove ".swift"
    }
}

// MARK: - Public Log File Access Functions
public extension GlobalLogger {
    func getLogFileURL() -> URL {
        return CHLogger.shared.getLogFileURL()
    }

    func getAllLogFileURLs() -> [URL] {
        return CHLogger.shared.getAllLogFileURLs()
    }

    func getLogFileContents() -> String? {
        return CHLogger.shared.getLogFileContents()
    }

    func clearLogFile() {
        CHLogger.shared.clearLogFile()
    }

    func getLogFileSize() -> Int64 {
        return CHLogger.shared.getLogFileSize()
    }

    func getFormattedLogEntries(limit: Int? = nil) -> [LogEntry] {
        return CHLogger.shared.getFormattedLogEntries(limit: limit)
    }

    func forceFlushLogs() {
        CHLogger.shared.forceFlushLogs()
    }
}
