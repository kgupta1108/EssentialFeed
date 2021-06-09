//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by kshitij gupta on 09/06/21.
//

import Foundation

public enum Result {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping ((Result) -> Void))
}
