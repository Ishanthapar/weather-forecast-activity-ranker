//
//  GeocodingModels.swift
//  ActivityPlanner
//
//  Created by Ishan Thapar on 11/2/26.
//

import Foundation

struct GeocodingResponse: Codable {
    let results: [GeocodedLocation]?
}

struct GeocodedLocation: Codable, Identifiable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    
    let country: String?
    let countryCode: String?
    let admin1: String?
    let timezone: String?
    let population: Int?
    let featureCode: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case latitude
        case longitude
        case country
        case countryCode = "country_code"
        case admin1
        case timezone
        case population
        case featureCode = "feature_code"
    }
}
