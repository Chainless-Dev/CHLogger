//
//  RedactedMessage.swift
//  CHLogger
//
//  Created by Alikhan Mussabekov on 20.06.2025.
//

import Foundation

public struct Redacted<T>: CustomStringConvertible {
    public let value: T
    public let placeholder: String
    internal let id = UUID().uuidString

    public init(_ value: T, placeholder: String = "[REDACTED]") {
        self.value = value
        self.placeholder = placeholder
    }

    public var description: String {
        // Use a unique marker that we can find and replace later
        return "<<REDACT_\(id)_\(value)_\(placeholder)>>"
    }
}

/// Helper function to create redacted values with common placeholders
public func redact<T>(_ value: T, as placeholder: String = "[REDACTED]") -> Redacted<T> {
    return Redacted(value, placeholder: placeholder)
}

/// Common redaction helpers
public extension Redacted where T: StringProtocol {
    static func email(_ email: T) -> Redacted<T> {
        return Redacted(email, placeholder: "[REDACTED_EMAIL]")
    }

    static func password(_ password: T) -> Redacted<T> {
        return Redacted(password, placeholder: "[REDACTED_PASSWORD]")
    }

    static func creditCard(_ card: T) -> Redacted<T> {
        return Redacted(card, placeholder: "[REDACTED_CARD]")
    }

    static func apiKey(_ key: T) -> Redacted<T> {
        return Redacted(key, placeholder: "[REDACTED_API_KEY]")
    }

    static func phone(_ phone: T) -> Redacted<T> {
        return Redacted(phone, placeholder: "[REDACTED_PHONE]")
    }
}
