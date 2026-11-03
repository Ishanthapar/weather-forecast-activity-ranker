//
//  AppContainer.swift
//  ActivityPlanner
//
//  Created by Ishan Thapar on 11/2/26.
//

import Foundation

struct AppContainer {
    // MARK: - Dependencies
    let urlSession: URLSession
    let geocodingService: any GeocodingServiceProtocol
    
    // MARK: - Initialization
    init(
        urlSession: URLSession = .shared
    ) {
        let apiClient = APIClient()
        self.geocodingService = GeocodingService(apiClient: apiClient)
        self.urlSession = urlSession
    }
}
