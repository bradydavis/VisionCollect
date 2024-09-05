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
    @State private var managedObjectContext: NSManagedObjectContext?

    var body: some Scene {
        WindowGroup {
            if let context = managedObjectContext {
                ContentView(context: context)
                    .environment(\.managedObjectContext, context)
            } else {
                Text("Loading...")
                    .onAppear(perform: setupContext)
            }
        }
    }

    private func setupContext() {
        DispatchQueue.main.async {
            self.managedObjectContext = persistenceController.container.viewContext
        }
    }
}
