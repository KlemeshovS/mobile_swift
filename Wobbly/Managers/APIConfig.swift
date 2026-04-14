//
//  APIConfig.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on [Date].
//

import Foundation

enum EnvironmentType {
    case staging
    case production

    var baseURL: String {
        switch self {
        case .staging:
            return "https://staging-api.wobbly.site/api/v1"
        case .production:
            return "https://api.wobbly.site/api/v1"
        }
    }

    var requiresStagingKey: Bool {
        return self == .staging
    }
}

enum AppEnvironment {
    static let current: EnvironmentType = {
        #if STAGING
        let env: EnvironmentType = .staging
        print("🌍 App Environment: STAGING")
        if stagingKey == nil {
            print("⚠️ Warning: STAGING_API_KEY environment variable is not set!")
        }
        #else
        let env: EnvironmentType = .production
        print("🌍 App Environment: PRODUCTION")
        #endif
        return env
    }()

    static var stagingKey: String? {
        return ProcessInfo.processInfo.environment["STAGING_API_KEY"]
    }
}
