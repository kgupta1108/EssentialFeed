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
 
        expect(sut: sut, toCompleteWithResult: .failure(RemoteFeedLoader.Error.connectivity)) {
              let clientError = NSError(domain: "Test", code: 0, userInfo: nil)
            client.complete(with: clientError)
        }
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { (index, code) in
            expect(sut: sut, toCompleteWithResult: .failure(RemoteFeedLoader.Error.invalidData)) {
                let json = makeItemsJSON(items: [])
                client.complete(withStatusCode: code, data: json, index: index)
            }
        }
    }
     
    func test_load_deliversErrorOnNon200HTTPResponseWithInvalidJson() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        expect(sut: sut, toCompleteWithResult: .failure(RemoteFeedLoader.Error.invalidData) ) {
            let invalidJson = Data(bytes: "Invalid JSON".utf8)
            client.complete(withStatusCode: 200, data: invalidJson)
        }
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyList() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        expect(sut: sut, toCompleteWithResult: .success([])) {
            let emptyListJSON = makeItemsJSON(items: [])
            client.complete(withStatusCode: 200, data: emptyListJSON)
        }
    }
    
    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
            let (sut, client) = makeSUT()

            let item1 = makeItem(
                id: UUID().uuidString,
                imageURL: URL(string: "http://a-url.com")!)

            let item2 = makeItem(
                id: UUID().uuidString,
                description: "a description",
                location: "a location",
                imageURL: URL(string: "http://another-url.com")!)

            let items = [item1.model, item2.model]

        expect(sut: sut, toCompleteWithResult: RemoteFeedLoader.Result.success(items), action: {
            let json = makeItemsJSON(items: [item1.json, item2.json])
                client.complete(withStatusCode: 200, data: json)
            })
        }
    
    func test_load_doesNotDeliverResultAfterSutInstanceIsDeallocated() {
        let client = HTTPClientSpy()
        let url = URL(string: "any-url.com")!
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
        
        var capturedResult = [RemoteFeedLoader.Result]()
        sut?.load { capturedResult.append($0) }
        
        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJSON(items: []))
        
        XCTAssertTrue(capturedResult.isEmpty)
    }

    // MARK: - Helpers
     
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!, file: StaticString = #file, line: UInt = #line) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        checkForMemoryLeaks(client)
        checkForMemoryLeaks(sut)
        return (sut, client)
    }
    
    private func checkForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential Memory leak", file: file, line: line)
        }
    }
    
    private func makeItem(id: String, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
        let feedItem = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        let json = [
            "id": feedItem.id,
            "description": feedItem.description,
            "location": feedItem.location,
            "image": feedItem.imageURL.absoluteString
        ] as [String : Any]
        return (feedItem, json)
    }
    
    private func makeItemsJSON(items: [[String: Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json )
    }
    
    private func expect(sut: RemoteFeedLoader, toCompleteWithResult expectedResult: RemoteFeedLoader.Result, action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        
        let exp = expectation(description: "wait for load completion")
        sut.load { (receivedResult) in
            switch(receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
            case let (.failure(receivedError), .failure(expectedError)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
                
            default:
                XCTFail("Expected Result \(expectedResult) got \(receivedResult)")
            }
            exp.fulfill()
        }
        action()
        
        wait(for: [exp], timeout: 1.0)
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
        
        func complete(withStatusCode code: Int, data: Data, index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index ], statusCode: code, httpVersion: nil, headerFields: nil)!
            messages[index].completion(Result.success(data, response))
        }
    }

}
