//
//  RemoteFeedLoaderLearningTests.swift
//  EssentialFeedTests
//
//  Created by kshitij gupta on 05/06/21.
//

import XCTest
@testable import EssentialFeed

enum FeedLoaderError: Error {
    case connectivity
    case invalidData
}

public protocol HTTPClientDummy {
    func get(from url: URL, completion: @escaping ((Error) -> Void))
}

//class RemoteFeedLoaderLearningTests: XCTestCase {
//    func test_load_deliversErrorOnClientError() {
//        var errorShownOnClient: [FeedLoaderError] = []
//        
//        var capturedErrors: [FeedLoaderError] = []
//        sut.load { capturedErrors.append($0) }
//        
//        let clientError = NSError(domain: "Test", code: 0, userInfo: [:])
//        client.complete(with: clientError)
//        XCTAssertEqual(errorShownOnClient, [.connectivity])
//    }
//    
//    func test_load_deliversInvalidDataErrorOnNon200HTTPResponse() {
//        var errorShownOnClient: [FeedLoaderError] = []
//        
//        let samples = [199, 201, 300, 400, 500]
//        
//        samples.enumerated().forEach { index, code in
//            var capturedErrors = [RemoteFeedLoader.Error]()
//            sut.load { capturedErrors.append($0) }
//            
//            client.complete(withStatusCode: code, at: index)
//            
//            XCTAssertEqual(capturedErrors, [.invalidData])
//        }
//    }
//    
//    private class HTTPClientSpyDummy: HTTPClientDummy {
//        private var messages: [(URL, ((Error) -> Void))] = []
//        
//        func get(from url: URL, completion: @escaping (Error) -> Void) {
//            messages.append((url, completion))
//        }
//        
//        func complete(with error: FeedLoaderError, at index: Int = 0) {
//            messages[index].completion(Result.failure(error))
//        }
//        
//        func complete(with statusCode: Int, at index: Int = 0) {
//            let response = HTTPURLResponse(url: messages[index].url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
//            messages[index].completion(Result.success(Data(), response))
//        }
//    }
//}
