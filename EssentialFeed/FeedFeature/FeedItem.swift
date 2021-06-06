//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by kshitij gupta on 05/06/21.
//

import Foundation

public struct FeedItem: Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let url: URL
}
