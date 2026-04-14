//
//  AppError.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 14.03.26.
//
import SwiftUI

// MARK: - Error Handling
enum AppError: LocalizedError {
    case dataMigrationFailed(Error)
    case exportFailed(Error)
    case importFailed(Error)
    case fileNotFound
    case invalidFileFormat
    
    var errorDescription: String? {
        switch self {
        case .dataMigrationFailed(let error):
            return "Ошибка миграции данных: \(error.localizedDescription)"
        case .exportFailed(let error):
            return "Ошибка экспорта: \(error.localizedDescription)"
        case .importFailed(let error):
            return "Ошибка импорта: \(error.localizedDescription)"
        case .fileNotFound:
            return "Файл не найден"
        case .invalidFileFormat:
            return "Неверный формат файла"
        }
    }
}
