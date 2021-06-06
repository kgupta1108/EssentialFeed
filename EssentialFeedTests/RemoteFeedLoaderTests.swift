//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by kshitij gupta on 04/06/21.
//

import XCTest
@testable import EssentialFeed

class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()

        XCTAssertNil(client.requestedURL)
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load { _ in }

        XCTAssertEqual(client.requestedURL, url)
        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load { _ in }
        sut.load { _ in }

        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
 
        expect(sut: sut, toCompleteWithResult: .failure(.connectivity)) {
              let clientError = NSError(domain: "Test", code: 0, userInfo: nil)
            client.complete(with: clientError)
        }
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { (index, code) in
            expect(sut: sut, toCompleteWithResult: .failure(.invalidData)) {
                client.complete(withStatusCode: code, index: index)
            }
        }
    }
    
    func test_load_deliversErrorOnNon200HTTPResponseWithInvalidJson() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        expect(sut: sut, toCompleteWithResult: .failure(.invalidData) ) {
            let invalidJson = Data(bytes: "Invalid JSON".utf8)
            client.complete(withStatusCode: 200, data: invalidJson)
        }
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyList() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        expect(sut: sut, toCompleteWithResult: .success([])) {
            let emptyListJSON = Data(bytes: "{\"items\": [] }".utf8)
            client.complete(withStatusCode: 200, data: emptyListJSON)
        }
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithNonEmptyList() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        let item1 = FeedItem(
                    id: UUID(),
                    description: nil,
                    location: nil,
                    imageURL: URL(string: "http://a-url.com")!)

                let item1JSON = [
                    "id": item1.id.uuidString,
                    "image": item1.imageURL.absoluteString
                ]

                let item2 = FeedItem(
                    id: UUID(),
                    description: "a description",
                    location: "a location",
                    imageURL: URL(string: "http://another-url.com")!)

                let item2JSON = [
                    "id": item2.id.uuidString,
                    "description": item2.description,
                    "location": item2.location,
                    "image": item2.imageURL.absoluteString
                ]

                let itemsJSON = [
                    "items": [item1JSON, item2JSON]
                ]
        
        expect(sut: sut, toCompleteWithResult: .success([item1, item2])) {
            let json = try? JSONSerialization.data(withJSONObject: itemsJSON)
            client.complete(withStatusCode: 200, data: json!)
        }
    }

    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private func expect(sut: RemoteFeedLoader, toCompleteWithResult result: RemoteFeedLoader.Result, action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        var capturedResult = [RemoteFeedLoader.Result]()
        sut.load { capturedResult.append($0) }

        action()
        
        XCTAssertEqual(capturedResult, [result], file: file, line: line)
    }

    private class HTTPClientSpy: HTTPClient {
        var requestedURL: URL?
        var completions: [((Result) -> Void)] = []
        private var messages = [(url: URL, completion: ((Result) -> Void))]()
        
        var requestedURLs: [URL] {
            return messages.map { $0.url }
        }


        func get(from url: URL, completion: @escaping ((Result) -> Void)) {
            requestedURL = url
            completions.append(completion)
            messages.append((url, completion))
        }
        
        func complete(with error: Error, index: Int = 0) {
            messages[index].completion(Result.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data = Data(), index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index ], statusCode: code, httpVersion: nil, headerFields: nil)!
            messages[index].completion(Result.success(data, response))
        }
    }

}
