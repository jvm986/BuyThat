//
//  PreviewContainer.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import SwiftUI
import SwiftData

@MainActor
struct PreviewContainer {
    let container: ModelContainer

    init() throws {
        let schema = Schema([
            ToBuyItem.self,
            ItemList.self,
            ItemListEntry.self,
            Store.self,
            StoreVariantInfo.self,
            Product.self,
            ProductVariant.self,
            PurchaseUnit.self,
            Brand.self,
            Tag.self
        ])

        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: configuration)

        // Add sample data
        addSampleData()
    }

    private func addSampleData() {
        let context = container.mainContext

        // Create Tags
        let organic = Tag(name: "Organic")
        let glutenFree = Tag(name: "Gluten Free")
        let vegan = Tag(name: "Vegan")
        context.insert(organic)
        context.insert(glutenFree)
        context.insert(vegan)

        // Create Brands
        let brandA = Brand(name: "Brand A")
        let brandB = Brand(name: "Brand B")
        context.insert(brandA)
        context.insert(brandB)

        // Create Products
        let milk = Product(name: "Milk")
        milk.tags = [organic]
        let bread = Product(name: "Bread")
        bread.tags = [glutenFree]
        let tofu = Product(name: "Tofu")
        tofu.tags = [vegan, organic]
        context.insert(milk)
        context.insert(bread)
        context.insert(tofu)

        // Create Product Variants
        let milkVariant = ProductVariant(
            product: milk,
            brand: brandA,
            baseUnit: .units
        )
        let breadVariant = ProductVariant(
            product: bread,
            brand: brandB,
            baseUnit: .units
        )
        let tofuVariant = ProductVariant(
            product: tofu,
            brand: brandA,
            baseUnit: .units
        )
        context.insert(milkVariant)
        context.insert(breadVariant)
        context.insert(tofuVariant)

        // Create Purchase Units
        let milkBottleUnit = PurchaseUnit(
            unit: .liters,
            conversionToBase: 1,
            isInverted: false,
            variant: milkVariant
        )
        let breadPackageUnit = PurchaseUnit(
            unit: .kilograms,
            conversionToBase: 0.5,
            isInverted: false,
            variant: breadVariant
        )
        let tofuPackageUnit = PurchaseUnit(
            unit: .kilograms,
            conversionToBase: 0.4,
            isInverted: false,
            variant: tofuVariant
        )
        context.insert(milkBottleUnit)
        context.insert(breadPackageUnit)
        context.insert(tofuPackageUnit)

        // Create Stores
        let supermarketA = Store(name: "Supermarket A")
        let supermarketB = Store(name: "Supermarket B")
        context.insert(supermarketA)
        context.insert(supermarketB)

        // Create Store Variant Info
        let milkAtA = StoreVariantInfo(
            variant: milkVariant,
            store: supermarketA,
            pricePerUnit: 2.49,
            pricingUnit: milkBottleUnit
        )
        let breadAtA = StoreVariantInfo(
            variant: breadVariant,
            store: supermarketA,
            pricePerUnit: 3.99,
            pricingUnit: breadPackageUnit
        )
        let tofuAtB = StoreVariantInfo(
            variant: tofuVariant,
            store: supermarketB,
            pricePerUnit: 2.99,
            pricingUnit: tofuPackageUnit
        )
        context.insert(milkAtA)
        context.insert(breadAtA)
        context.insert(tofuAtB)

        // Create To Buy Items
        let item1 = ToBuyItem(storeVariantInfo: milkAtA, quantity: "2")
        let item2 = ToBuyItem(storeVariantInfo: breadAtA, quantity: "1")
        let item3 = ToBuyItem(storeVariantInfo: tofuAtB, quantity: "3")
        context.insert(item1)
        context.insert(item2)
        context.insert(item3)

        // Create a template list
        let weeklyList = ItemList(name: "Weekly Groceries")
        context.insert(weeklyList)

        let entry1 = ItemListEntry(storeVariantInfo: milkAtA, quantity: "2", list: weeklyList)
        let entry2 = ItemListEntry(storeVariantInfo: breadAtA, quantity: "1", list: weeklyList)
        let entry3 = ItemListEntry(product: tofu, quantity: "1", list: weeklyList)
        context.insert(entry1)
        context.insert(entry2)
        context.insert(entry3)

        try? context.save()
    }
}

extension PreviewContainer {
    static var sample: ModelContainer {
        do {
            return try PreviewContainer().container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
}
