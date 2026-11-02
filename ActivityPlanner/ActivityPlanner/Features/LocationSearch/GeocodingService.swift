//
//  GeocodingService.swift
//  ActivityPlanner
//
//  Created by Ishan Thapar on 11/2/26.
//

import Foundation

protocol GeocodingServiceProtocol {
    func searchLocations(
        matching query: String
    ) async throws -> [GeocodedLocation]
}

struct GeocodingService: GeocodingServiceProtocol {
    private let apiClient: APIClientProtocol
    
    private let baseURL = URL(
        string: "https://geocoding-api.open-meteo.com/v1/search"
    ) ?? URL.init(filePath: .localizedName(of: .ascii))
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    func searchLocations(
        matching query: String
    ) async throws -> [GeocodedLocation] {
        let searchTerm = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        guard searchTerm.count >= 2 else {
            return []
        }
        
        guard var components = URLComponents(
            url: baseURL,
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.invalidResponse
        }
        
        components.queryItems = [
            URLQueryItem(name: "name", value: searchTerm),
            URLQueryItem(name: "count", value: "10"),
            URLQueryItem(name: "language", value: "en")
        ]
        
        guard let url = components.url else {
            throw APIError.invalidResponse
        }
        
        let response = try await apiClient.get(
            GeocodingResponse.self,
            from: url)
        
        return response.results ?? []
    }
}
