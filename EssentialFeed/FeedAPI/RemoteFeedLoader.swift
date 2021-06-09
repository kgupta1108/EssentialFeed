//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by kshitij gupta on 04/06/21.
//

import Foundation

public enum Result {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping ((Result) -> Void))
}

public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
 
    public func load(completion: @escaping ((Result) -> Void)) {
        client.get(from: url) { result in
            switch result {
            case let .success(data, response):
                do {
                    let items = try FeedItemsMapper.map(data, response)
                    completion(.success(items))
                }  catch {
                    completion(.failure(.invalidData ))
                }
            case .failure:
                completion(.failure(.connectivity ))
            }
        }
    }
}

private class FeedItemsMapper {
    
    static var OK_200: Int {
        return 200
    }
    
    private struct Root: Decodable {
        let items: [Item]
    }

    private struct Item: Decodable {
        let id: String
        let description: String?
        let location: String?
        let image: URL
        
        var item: FeedItem {
            return FeedItem(id: id, description: description, location: location, imageURL: image)
        }
    }
    
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [ FeedItem] {
        guard response.statusCode == OK_200 else {
            throw RemoteFeedLoader.Error.invalidData
        }
        let root = try JSONDecoder().decode(Root.self, from: data)
        return root.items.map( { $0.item } )
    }
}


