//
//  Bundle+Extensions.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 13.01.2026.
//
import Foundation

extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var appVersionFull: String {
        return "\(appVersion) (\(buildNumber))"
    }
    
    var appName: String {
        return infoDictionary?["CFBundleName"] as? String ?? "Wobbly"
    }
    
    var appDisplayName: String {
        return infoDictionary?["CFBundleDisplayName"] as? String ?? appName
    }
    
    var bundleIdentifier: String {
        return infoDictionary?["CFBundleIdentifier"] as? String ?? ""
    }
}
