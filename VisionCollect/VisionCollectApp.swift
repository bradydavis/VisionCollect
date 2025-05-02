//
//  VisionCollectApp.swift
//  VisionCollect
//
//  Created by Brady Davis on 9/5/24.
//

import SwiftUI
import CoreData

@main
struct VisionCollectApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView(context: persistenceController.container.viewContext)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
