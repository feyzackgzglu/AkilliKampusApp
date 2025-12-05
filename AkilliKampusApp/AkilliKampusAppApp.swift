//
//  AkilliKampusAppApp.swift
//  AkilliKampusApp
//
//  Created by Feyza on 5.12.2025.
//

import SwiftUI

@main
struct AkilliKampusAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
