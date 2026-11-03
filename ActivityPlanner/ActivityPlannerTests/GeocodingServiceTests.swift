//
//  GeocodingServiceTests.swift
//  ActivityPlanner
//
//  Created by Ishan Thapar on 11/2/26.
//

import Foundation
import XCTest
@testable import ActivityPlanner

final class GeocodingServiceTests: XCTestCase {
    private var session: URLSession!
    private var sut: GeocodingService!
    
    override func setUp() {
        super.setUp()
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        
        session = URLSession(configuration: configuration)
        
        let apiClient = APIClient(session: session)
        sut = GeocodingService(apiClient: apiClient)
    }
    
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        session.invalidateAndCancel()
        
        session = nil
        
        sut = nil
        
        super.tearDown()
    }
    
    // MARK: - Empty Query
    
    func testWhenQueryIsEmpty() async throws {
        MockURLProtocol.requestHandler = { _ in
            XCTFail("No network request should be made for an empty query")
            throw URLError(.badURL)
        }
        
        let results = try await sut.searchLocations(matching: "   ")
        
        XCTAssertTrue(results.isEmpty)
    }
    
    // MARK: - Minimum Query Length
    
    func testWhenQueryContainsOneCharacter() async throws {
        
        MockURLProtocol.requestHandler = { _ in
            XCTFail("No network request should be made for a one-character query")
            throw URLError(.badURL)
        }
        let results = try await sut.searchLocations(matching: "M")
        
        XCTAssertTrue(results.isEmpty)
    }
    
    // MARK: - Successful Search
    
    func testWhenQueryIsValid() async throws {
        // Arrange
        let responseJSON = """
            {
                "results": [
                    {
                        "id": 1275339,
                        "name": "Mumbai",
                        "latitude": 19.0728,
                        "longitude": 72.8826,
                        "country": "India",
                        "country_code": "IN",
                        "admin1": "Maharashtra",
                        "timezone": "Asia/Kolkata"
                    }
                ]
            }
            """
        
        MockURLProtocol.requestHandler = { request in
            
            XCTAssertEqual(request.httpMethod, "GET")
            
            let components = URLComponents(
                url: request.url!,
                resolvingAgainstBaseURL: false
            )
            
            XCTAssertEqual(
                components?.queryItems?.first(where: { $0.name == "name" })?.value,
                "Mumbai"
            )
            
            XCTAssertEqual(
                components?.queryItems?.first(where: { $0.name == "count" })?.value,
                "10"
            )
            
            XCTAssertEqual(
                components?.queryItems?.first(where: { $0.name == "language" })?.value,
                "en"
            )
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            return (response, Data(responseJSON.utf8))
        }
        
        let results = try await sut.searchLocations(
            matching: "  Mumbai  "
        )
        
        XCTAssertEqual(results.count, 1)
        
        let location = try XCTUnwrap(results.first)
        
        XCTAssertEqual(location.id, 1275339)
        XCTAssertEqual(location.name, "Mumbai")
        XCTAssertEqual(location.latitude, 19.0728)
        XCTAssertEqual(location.longitude, 72.8826)
        XCTAssertEqual(location.country, "India")
        XCTAssertEqual(location.countryCode, "IN")
        XCTAssertEqual(location.admin1, "Maharashtra")
        XCTAssertEqual(location.timezone, "Asia/Kolkata")
    }
    
    // MARK: - Empty Results
    
    func testWhenResponseDoesNotContainResults() async throws {
        
        let responseJSON = "{}"
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            return (response, Data(responseJSON.utf8))
        }
        
        
        let results = try await sut.searchLocations(
            matching: "UnknownCity"
        )
        
        
        XCTAssertTrue(results.isEmpty)
    }
    
    // MARK: - HTTP Errors
    
    func testWhenServerReturnsHTTPError() async {
        
        let errorJSON = """
            {
                "reason": "Invalid query parameter"
            }
            """
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: nil
            )!
            
            return (response, Data(errorJSON.utf8))
        }
        
        do {
            let _: [GeocodedLocation] = try await sut.searchLocations(
                matching: "Mumbai"
            )
            
            XCTFail("Expected an HTTP error")
            
        } catch let error as APIError {
            guard case let .httpStatus(code, message) = error else {
                return XCTFail("Unexpected APIError: \(error)")
            }
            
            XCTAssertEqual(code, 400)
            XCTAssertEqual(message, "Invalid query parameter")
            
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
