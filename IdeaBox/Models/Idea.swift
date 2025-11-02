//
//  Idea.swift
//  IdeaBox
//
//  Created by Harry Ng on 10/1/25.
//

import Foundation
import SwiftData

@Model
final class Idea {
    var id: UUID = UUID()
    var title: String = ""
    var detail: String?
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var sortOrder: Double?
    
    init(
        id: UUID = UUID(),
        title: String,
        detail: String? = nil,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        sortOrder: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sortOrder = sortOrder
    }
}
