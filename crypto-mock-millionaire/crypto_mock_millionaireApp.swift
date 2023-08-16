//
//  crypto_mock_millionaireApp.swift
//  crypto-mock-millionaire
//
//  Created by Adam Pagels on 2023-08-16.
//

import SwiftUI

@main
struct crypto_mock_millionaireApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
