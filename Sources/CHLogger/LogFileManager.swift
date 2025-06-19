//
//  LogFileManager.swift
//  CHLogger
//
//  Created by Alikhan Mussabekov on 19.06.2025.
//

import Foundation

internal extension CHLogger {
    /// Get formatted log entries for display in UI
    func getFormattedLogEntries(limit: Int? = nil) -> [LogEntry] {
        guard let contents = getLogFileContents() else { return [] }

        let lines = contents.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        let entries = lines.compactMap { line -> LogEntry? in
            return LogEntry.parse(from: line)
        }

        if let limit = limit {
            return Array(entries.suffix(limit))
        }

        return entries
    }
}
