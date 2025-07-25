//
//  Meditation_BuilderApp.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI
import SwiftData

// Import our logging utility
import os.log

@main
struct Meditation_BuilderApp: App {
    // Initialize logger at app startup
    @StateObject private var appLogger = AppLogger.shared
    private let modelContainer: ModelContainer
    
    init() {
        print("Meditation_BuilderApp: init() called")
        // Test logger immediately
        logger.info("App initialization started", category: "AppLifecycle")
        
        // Initialize ModelContainer first
        let container = Self.createModelContainer()
        self.modelContainer = container
        
        // Configure RoutineDataManager after modelContainer is initialized
        let context = ModelContext(container)
        RoutineDataManager.shared.configure(with: context)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Test if logger is accessible
                    print("Testing logger accessibility...")
                    logger.info("App launched", category: "AppLifecycle")
                    print("Logger test completed")
                    
                    // Initialize sample data if needed
                    Task {
                        await initializeSampleDataIfNeeded()
                    }
                }
                .onDisappear {
                    logger.info("App will disappear", category: "AppLifecycle")
                }
        }
        .modelContainer(modelContainer)
        .environment(\.routineDataManager, RoutineDataManager.shared)
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }
    
    @Environment(\.scenePhase) private var scenePhase
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            logger.info("App became active", category: "AppLifecycle")
        case .inactive:
            logger.info("App became inactive", category: "AppLifecycle")
        case .background:
            logger.info("App entered background", category: "AppLifecycle")
            // Save logger settings when app goes to background
            appLogger.saveSettings()
        @unknown default:
            logger.warning("Unknown scene phase: \(phase)", category: "AppLifecycle")
        }
    }
    
    // Make createModelContainer static so it can be called during initialization
    private static func createModelContainer() -> ModelContainer {
        logger.info("Creating SwiftData model container", category: "Data")
        
        let schema = Schema([
            SavedRoutine.self,
            MeditationBlock.self, 
            MediaResource.self,
            MeditationSession.self,
            SessionBlockRecord.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            logger.info("SwiftData model container created successfully", category: "Data")
            return container
        } catch {
            // If container creation fails due to schema changes, clear and recreate
            logger.error("Failed to create model container: \(error)", category: "Data")
            logger.info("Attempting to create fresh container...", category: "Data")
            
            // Try to clear the existing database files
            clearDatabaseFiles()
            
            do {
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                logger.info("Fresh model container created successfully", category: "Data")
                return container
            } catch {
                // Last resort: use in-memory store for this session
                logger.error("Still failed, using in-memory store: \(error)", category: "Data")
                let memoryConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
                
                do {
                    let container = try ModelContainer(for: schema, configurations: [memoryConfiguration])
                    logger.warning("Using in-memory model container as fallback", category: "Data")
                    return container
                } catch {
                    logger.critical("Could not create ModelContainer: \(error)", category: "Data")
                    fatalError("Could not create ModelContainer: \(error)")
                }
            }
        }
    }
    
    private static func clearDatabaseFiles() {
        do {
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
                logger.info("Cleared existing database at: \(url)", category: "Data")
            }
        } catch {
            logger.error("Failed to clear database files: \(error)", category: "Data")
        }
    }
    
    @MainActor
    private func initializeSampleDataIfNeeded() async {
        logger.info("Initializing sample data if needed", category: "Data")
        do {
            try RoutineDataManager.shared.initializeSampleDataIfNeeded()
            logger.info("Sample data initialization completed", category: "Data")
        } catch {
            logger.error("Failed to initialize sample data: \(error)", category: "Data")
        }
    }
}
