//
//  BuyThatApp.swift
//  BuyThat
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
            PriceHistory.self,
            ShoppingList.self,
            ShoppingListItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

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
        .modelContainer(sharedModelContainer)
    }
}
