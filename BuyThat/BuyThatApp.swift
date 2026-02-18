//
//  BuyThatApp.swift
//
//  Created by James Maguire on 30.11.25.
//

import SwiftUI
import SwiftData

@main
struct BuyThatApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Product.self,
            Brand.self,
            Store.self,
            Tag.self,
            ProductVariant.self,
            PurchaseUnit.self,
            StoreVariantInfo.self,
            ToBuyItem.self,
            ItemList.self,
            ItemListEntry.self,
            ShoppingTrip.self,
            ShoppingTripItem.self,
        ])

        // Use in-memory storage for UI testing to ensure clean state
        let isUITesting = ProcessInfo.processInfo.arguments.contains("UI-TESTING")
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isUITesting)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
