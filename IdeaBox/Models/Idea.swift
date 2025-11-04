//
//  Idea.swift
//  IdeaBox
//
//  Created by Harry Ng on 10/1/25.
//


import Foundation

struct Idea: Identifiable {
    let id: UUID
    var title: String
    var description: String
    var isCompleted: Bool

    init(id: UUID = UUID(), title: String, description: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
    }
}

// MARK: - Mock Data
extension Idea {
    static let mockIdeas: [Idea] = [
        Idea(
            title: "Build IdeaBox App",
            description: "Create a native iOS app for managing ideas with Liquid Glass materials"
        ),
        Idea(
            title: "Learn SwiftUI Animations",
            description: "Master smooth transitions and interactive animations in SwiftUI"
        ),
        Idea(
            title: "Write Technical Blog",
            description: "Share insights about iOS development and best practices",
            isCompleted: true
        ),
        Idea(
            title: "Redesign Portfolio",
            description: "Update personal website with latest projects and modern design"
        ),
        Idea(
            title: "Contribute to Open Source",
            description: "Find interesting Swift packages to contribute to"
        ),
        Idea(
            title: "Study Design Patterns",
            description: "Deep dive into MVVM, Coordinator, and other architectural patterns",
            isCompleted: true
        ),
        Idea(
            title: "Attend WWDC Session",
            description: "Watch sessions about iOS 26 features and Liquid Glass materials"
        )
    ]
}
