//
//  Meditation_BuilderApp.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI
import SwiftData

@main
struct Meditation_BuilderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Initialize sample data if needed
                    Task {
                        await initializeSampleDataIfNeeded()
                    }
                }
        }
        .modelContainer(createModelContainer())
    }
    
    private func createModelContainer() -> ModelContainer {
        let schema = Schema([
            SavedRoutine.self,
            MeditationBlock.self, 
            MediaResource.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If container creation fails due to schema changes, clear and recreate
            print("Failed to create model container: \(error)")
            print("Creating fresh container...")
            
            // Try to clear the existing database files
            clearDatabaseFiles()
            
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                // Last resort: use in-memory store for this session
                print("Still failed, using in-memory store: \(error)")
                let memoryConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
                
                do {
                    return try ModelContainer(for: schema, configurations: [memoryConfiguration])
                } catch {
                    fatalError("Could not create ModelContainer: \(error)")
                }
            }
        }
    }
    
    private func clearDatabaseFiles() {
        do {
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
                print("Cleared existing database at: \(url)")
            }
        } catch {
            print("Failed to clear database files: \(error)")
        }
    }
    
    @MainActor
    private func initializeSampleDataIfNeeded() async {
        do {
            let context = ModelContext(createModelContainer())
            let dataManager = RoutineDataManager(context: context)
            try dataManager.initializeSampleDataIfNeeded()
        } catch {
            print("Failed to initialize sample data: \(error)")
        }
    }
}
