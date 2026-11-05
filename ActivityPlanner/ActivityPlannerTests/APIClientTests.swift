//
//  APIClientTests.swift
//  ActivityPlanner
//
//  Created by Ishan Thapar on 11/2/26.
//

import XCTest
@testable import ActivityPlanner

///
/// This is a test only networking substitute
///
final class MockURLProtocol: URLProtocol {
    
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }
    
    override class func canonicalRequest(
        for request: URLRequest
    ) -> URLRequest {
        request
    }
    
    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(
                self,
                didFailWithError: URLError(.unknown))
            return
        }
        
        do {
            let (response, data) = try handler(request)
            
            client?.urlProtocol(
                self,
                didReceive: response,
                cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
            
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
        
    }
    
    override func stopLoading() {}
}

final class APIClientTests: XCTestCase {
    private var session: URLSession!
    private var apiClient: APIClient!
    
    override func setUp() {
        super.setUp()
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        
        session = URLSession(configuration: configuration)
        apiClient = APIClient(session: session)
    }
    
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        session.invalidateAndCancel()
        
        session = nil
        apiClient = nil
        
        super.tearDown()
    }
    
    func testServerSuccessWithDecodableResponse() async throws {
        let expectedPayload = """
            {
                "name": "Mumbai"
            }
            """
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
            
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            return (response, Data(expectedPayload.utf8))
        }
        
        let url = URL(string: "https://example.com/test")!
        
        let result = try await apiClient.get(
            TestPayload.self, from: url
        )
        
        XCTAssertEqual(result.name, "Mumbai")
    }
    
    func testServerError() async {
        let errorPayload = """
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
            
            return (response, Data(errorPayload.utf8))
        }
        
        let url = URL(string: "https://example.com/test")!
        
        do {
            
            let _: TestPayload = try await apiClient.get(
                TestPayload.self,
                from: url
            )
            
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
    
    func testInvalidResponseAndDecodingError() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            
            return (response, Data("not valid JSON".utf8))
        }
        
        let url = URL(string: "https://example.com/test")!
        
        do {
            let _: TestPayload = try await apiClient.get(
                TestPayload.self,
                from: url
            )
            
            XCTFail("Expected a decoding error")
            
        } catch let error as APIError {
            guard case .decodingFailed = error else {
                return XCTFail("Unexpected APIError: \(error)")
            }

        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private struct TestPayload: Decodable {
    let name: String
}
