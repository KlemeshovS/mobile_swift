// String+Localized.swift
import Foundation

// Это альтернатива, можно использовать вместо NSLocalizedString
extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}
