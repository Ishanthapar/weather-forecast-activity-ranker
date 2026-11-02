//
//  APIClient.swift
//  ActivityPlanner
//
//  Created by Ishan Thapar on 11/2/26.
//

import Foundation

protocol APIClientProtocol {
    func get<T: Decodable>(
        _ type: T.Type,
        from url: URL
    ) async throws -> T
}

struct APIClient: APIClientProtocol {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func get<T: Decodable>(
        _ type: T.Type,
        from url: URL
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = try? JSONDecoder().decode(APIErrorResponse.self, from: data).reason
            throw APIError.httpStatus(code: httpResponse.statusCode, message: message)
        }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }
}

private struct APIErrorResponse: Decodable {
    let reason: String?
}
