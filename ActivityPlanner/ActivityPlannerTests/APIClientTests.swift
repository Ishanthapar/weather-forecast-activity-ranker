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
