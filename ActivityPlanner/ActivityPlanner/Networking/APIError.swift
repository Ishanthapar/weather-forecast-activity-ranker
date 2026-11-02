//
//  APIError.swift
//  ActivityPlanner
//
//  Created by Ishan Thapar on 11/2/26.
//

import Foundation

enum APIError: Error {
    case invalidResponse
    case httpStatus(code: Int, message: String?)
    case decodingFailed
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an invalid response."
            
        case let .httpStatus(code, message):
            return message ?? "The server returned an HTTP status \(code)"
            
        case .decodingFailed:
            return "The server response couldn't be processed"
        }
    }
}
