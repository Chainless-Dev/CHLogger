//
//  LogLevel.swift
//  CHLogger
//
//  Created by Alikhan Mussabekov on 19.06.2025.
//

import Foundation
import OSLog

public enum LogLevel: Int, CaseIterable, Sendable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case critical = 4

    var emoji: String {
        switch self {
        case .debug: return "🐛"
        case .info: return "💙"
        case .warning: return "⚠️"
        case .error: return "❤️"
        case .critical: return "💀"
        }
    }

    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .critical: return .fault
        }
    }
}
