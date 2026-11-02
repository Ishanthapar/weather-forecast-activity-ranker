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
    
    // MARK: - Initialization
    init(
        urlSession: URLSession = .shared
    ) {
        self.urlSession = urlSession
    }
}
