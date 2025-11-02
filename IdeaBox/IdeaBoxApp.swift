//
//  IdeaBoxApp.swift
//  IdeaBox
//
//  Created by Harry Ng on 10/1/25.
//

import SwiftUI
import SwiftData

@main
struct IdeaBoxApp: App {
    var modelContainer: ModelContainer = {
        let schema = Schema([
            Idea.self
        ])
        
        // Configure for CloudKit sync
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.buildwithharry.IdeaBox")
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
