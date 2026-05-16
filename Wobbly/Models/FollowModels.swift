//
//  FollowModels.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 14.05.26.
//

import Foundation

struct FollowModel: Codable, Identifiable {
    let userId: Int
    let username: String
    let avatarUrl: String?
    let isMutual: Bool
    let createdAt: String?
    
    var id: Int { userId }
}

struct FollowListResponse: Codable {
    let items: [FollowModel]
    let total: Int
}
