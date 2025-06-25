//
//  LogEntry.swift
//  CHLogger
//
//  Created by Alikhan Mussabekov on 19.06.2025.
//

import Foundation

public struct LogEntry {
    public let timestamp: Date
    public let level: LogLevel
    public let className: String
    public let lineNumber: Int?
    public let message: String
    public let emoji: String

    static func parse(from line: String) -> LogEntry? {
        // Parse format: [timestamp] LEVEL emoji [ClassName:lineNumber] message or [timestamp] LEVEL emoji [ClassName] message
        let pattern = #"\[(.*?)\] (\w+) (.*?) \[(.*?)(?::(\d+))?\] (.*)"#

        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }

        let timestampStr = String(line[Range(match.range(at: 1), in: line)!])
        let levelStr = String(line[Range(match.range(at: 2), in: line)!])
        let emoji = String(line[Range(match.range(at: 3), in: line)!])
        let className = String(line[Range(match.range(at: 4), in: line)!])
        
        // Check if line number exists (group 5)
        let lineNumber: Int?
        if match.range(at: 5).location != NSNotFound {
            let lineNumStr = String(line[Range(match.range(at: 5), in: line)!])
            lineNumber = Int(lineNumStr)
        } else {
            lineNumber = nil
        }
        
        let message = String(line[Range(match.range(at: 6), in: line)!])

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        guard let timestamp = dateFormatter.date(from: timestampStr) else {
            return nil
        }

        // Convert level string to LogLevel enum
        let level: LogLevel
        switch levelStr.uppercased() {
        case "0", "DEBUG": level = .debug
        case "1", "INFO": level = .info
        case "2", "WARNING": level = .warning
        case "3", "ERROR": level = .error
        case "4", "CRITICAL": level = .critical
        default: return nil
        }

        return LogEntry(
            timestamp: timestamp,
            level: level,
            className: className,
            lineNumber: lineNumber,
            message: message,
            emoji: emoji
        )
    }
}
