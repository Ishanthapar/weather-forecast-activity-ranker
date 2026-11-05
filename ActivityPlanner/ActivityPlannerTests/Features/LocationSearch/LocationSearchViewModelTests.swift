//
//  LocationSearchViewModelTests.swift
//  ActivityPlannerTests
//
//  Created by Ishan Thapar on 11/3/26.
//

import Foundation
import XCTest
@testable import ActivityPlanner

/// A mock service will let us control what the service returns and will not
/// require unit tests to depend on Internet connectivity and API availability
/// and response times
final class MockGeocodingService: GeocodingServiceProtocol {
    
    private(set) var receivedQueries: [String] = []
    
    var searchHandler: ((String) async throws -> [GeocodedLocation])?
    
    func searchLocations(
        matching query: String
    ) async throws -> [GeocodedLocation] {
        
        receivedQueries.append(query)
        
        guard let searchHandler else {
            return []
        }
        
        return try await searchHandler(query)
    }
}

@MainActor
final class LocationSearchViewModelTests: XCTestCase {
    private var mockService: MockGeocodingService!
    private var locationSearchViewModel: LocationSearchViewModel!
    
    override func setUp() {
        super.setUp()
        
        mockService = MockGeocodingService()
        
        locationSearchViewModel = LocationSearchViewModel(
            geocodingService: mockService
        )
    }
    
    func testInitialIdleState() {
        if case .idle = locationSearchViewModel.state {
            XCTAssertTrue(true)
        }
        else {
            XCTFail("Expected initial state to be idle")
        }
    }
    
    func testShortQueryDoesNotCallAPI() {
        locationSearchViewModel.search(query: "M", debounce: false)
        
        if case .idle = locationSearchViewModel.state {
            XCTAssertTrue(true)
        }
        else {
            XCTFail("Expected state to remain idle")
        }
        
        XCTAssertTrue(mockService.receivedQueries.isEmpty)
    }
    
    func testSuccessfulSearchReturnsLocations() async {
        let mumbai = makeLocation(
            id: 1,
            name: "Mumbai"
        )
        
        mockService.searchHandler = { _ in
            [mumbai]
        }
        
        locationSearchViewModel.search(query: "Mumbai", debounce: false)
        
        let completed = await waitUntil {
            if case.results = self.locationSearchViewModel.state {
                return true
            }
            
            return false
        }
        
        XCTAssertTrue(completed)
        
        if case let .results(locations) = locationSearchViewModel.state {
            XCTAssertEqual(locations.count, 1)
            XCTAssertEqual(locations.first?.name, "Mumbai")
        }
        else {
            XCTFail("Expected search results")
        }
        
        XCTAssertEqual(mockService.receivedQueries, ["Mumbai"])
    }
    
    func testEmptySearchResponseProducesEmptyState() async {
        mockService.searchHandler = { _ in [] }
        
        locationSearchViewModel.search(query: "UnknownCity", debounce: false)
        
        let completed = await waitUntil {
            if case .empty = self.locationSearchViewModel.state {
                return true
            }
            
            return false
        }
        
        XCTAssertTrue(completed)
    }
    
    func testSearchFailureProducesFailedState() async {
        mockService.searchHandler = { _ in
            throw MockSearchError.failed
        }
        
        locationSearchViewModel.search(query: "Mumbai", debounce: false)
        
        let completed = await waitUntil {
            if case .failed = self.locationSearchViewModel.state {
                return true
            }
            
            return false
        }
        
        XCTAssertTrue(completed)
        
        if case let .failed(message) = locationSearchViewModel.state {
            XCTAssertEqual(message, "Mock search failed")
        }
        else {
            XCTFail("Expected failed state")
        }
    }
    
    private func makeLocation(
        id: Int,
        name: String
    ) -> GeocodedLocation {
        GeocodedLocation(
            id: id,
            name: name,
            latitude: 19.0760,
            longitude: 72.8777,
            country: "India",
            countryCode: "IN",
            admin1: "Maharashtra",
            timezone: "Asia/Kolkata",
            population: 1000000,
            featureCode: "PPLA"
        )
    }
    
    private func waitUntil(
        timeout: Duration = .seconds(2),
        condition: @escaping @MainActor () -> Bool
    ) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout
        
        while clock.now < deadline {
            if condition() {
                return true
            }
            
            try? await Task.sleep(for: .milliseconds(10))
        }
        
        return condition()
    }
}

private enum MockSearchError: LocalizedError {
    case failed
    
    var errorDescription: String? {
        "Mock search failed"
    }
}

