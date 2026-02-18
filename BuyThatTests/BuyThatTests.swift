//
//  BuyThatTests.swift
//  BuyThatTests
//
//  Created by James Maguire on 30.11.25.
//

import Testing
import SwiftData
import Foundation
@testable import BuyThat

// MARK: - Test Helper

extension BuyThatTests {
    /// Creates an in-memory ModelContext for testing
    func makeTestContainer() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Product.self, ProductVariant.self, PurchaseUnit.self,
                 StoreVariantInfo.self, Store.self, Brand.self,
                 ToBuyItem.self, ItemList.self, ItemListEntry.self, Tag.self,
            configurations: config
        )
        return ModelContext(container)
    }
}

// MARK: - Price Conversion Tests

@Suite("Price Conversion")
struct PriceConversionTests {
    let testHelper = BuyThatTests()

    @Test("Convert price between purchase units")
    func basicPriceConversion() async throws {
        let context = try testHelper.makeTestContainer()

        // Setup: Milk with base unit milliliters
        let product = Product(name: "Milk")
        let variant = ProductVariant(product: product, brand: nil, baseUnit: .liters)

        // Pricing unit: 1L bottle (conversionToBase = 1, meaning 1 bottle = 1L base)
        let pricingUnit = PurchaseUnit(unit: .liters, conversionToBase: 1, variant: variant)

        // Purchase unit: 500ml bottle (conversionToBase = 2, meaning 2 bottles = 1L base)
        let purchaseUnit = PurchaseUnit(unit: .liters, conversionToBase: 2, variant: variant)

        let store = Store(name: "Test Store")

        // Store info: Price per 1L = €2.00
        let storeInfo = StoreVariantInfo(
            variant: variant,
            store: store,
            pricePerUnit: Decimal(2.00),
            pricingUnit: pricingUnit
        )

        context.insert(product)
        context.insert(variant)
        context.insert(pricingUnit)
        context.insert(purchaseUnit)
        context.insert(store)
        context.insert(storeInfo)
        try context.save()

        // Expected: Price per 500ml = €2.00 × (1/2) = €1.00
        let price = storeInfo.priceForPurchaseUnit(purchaseUnit)
        #expect(price == Decimal(1.00))
    }

    @Test("Price conversion with inverted unit")
    func invertedUnitConversion() async throws {
        let context = try testHelper.makeTestContainer()

        // Setup: Sauce with base unit grams
        let product = Product(name: "Sauce")
        let variant = ProductVariant(product: product, brand: nil, baseUnit: .kilograms)

        // Pricing unit: 800g bottle (conversionToBase = 0.00125, inverted)
        // User entered "1 bottle = 800g", stored as 800 bottles = 1g
        let pricingUnit = PurchaseUnit(unit: .kilograms, conversionToBase: 0.00125, isInverted: true, variant: variant)

        // Purchase unit: per gram (conversionToBase = 1, meaning 1g = 1g base)
        let purchaseUnit = PurchaseUnit(unit: .kilograms, conversionToBase: 1, variant: variant)

        let store = Store(name: "Test Store")

        // Store info: Price per 800g bottle = €3.20
        let storeInfo = StoreVariantInfo(
            variant: variant,
            store: store,
            pricePerUnit: Decimal(string: "3.20")!,
            pricingUnit: pricingUnit
        )

        context.insert(product)
        context.insert(variant)
        context.insert(pricingUnit)
        context.insert(purchaseUnit)
        context.insert(store)
        context.insert(storeInfo)
        try context.save()

        // Expected: Price per gram = €3.20 × (0.00125/1) = €0.004
        let price = storeInfo.priceForPurchaseUnit(purchaseUnit)
        #expect(price == Decimal(string: "0.004")!)
    }

    @Test("Price when pricing unit equals base unit")
    func basePricingUnit() async throws {
        let context = try testHelper.makeTestContainer()

        // Setup: Apples sold by unit count
        let product = Product(name: "Apples")
        let variant = ProductVariant(product: product, brand: nil, baseUnit: .units)

        // No pricing unit (sold in base units)
        let purchaseUnit = PurchaseUnit(unit: .units, conversionToBase: 1, variant: variant)

        let store = Store(name: "Test Store")

        // Store info: Price per unit = €0.50
        let storeInfo = StoreVariantInfo(
            variant: variant,
            store: store,
            pricePerUnit: Decimal(string: "0.50")!,
            pricingUnit: nil
        )

        context.insert(product)
        context.insert(variant)
        context.insert(purchaseUnit)
        context.insert(store)
        context.insert(storeInfo)
        try context.save()

        // Expected: Price per unit = €0.50 (no conversion, sourceFactor defaults to 1.0)
        let price = storeInfo.priceForPurchaseUnit(purchaseUnit)
        #expect(price == Decimal(string: "0.50")!)
    }

    @Test("Price survives deleted pricing unit")
    func deletedPricingUnit() async throws {
        let context = try testHelper.makeTestContainer()

        // Setup: Juice with pricing unit
        let product = Product(name: "Juice")
        let variant = ProductVariant(product: product, brand: nil, baseUnit: .liters)

        let pricingUnit = PurchaseUnit(unit: .liters, conversionToBase: 2, variant: variant)
        let purchaseUnit = PurchaseUnit(unit: .liters, conversionToBase: 4, variant: variant)

        let store = Store(name: "Test Store")

        // Store info stores pricingUnitConversion on init
        let storeInfo = StoreVariantInfo(
            variant: variant,
            store: store,
            pricePerUnit: Decimal(4.00),
            pricingUnit: pricingUnit
        )

        context.insert(product)
        context.insert(variant)
        context.insert(pricingUnit)
        context.insert(purchaseUnit)
        context.insert(store)
        context.insert(storeInfo)
        try context.save()

        // Verify pricingUnitConversion was stored
        #expect(storeInfo.pricingUnitConversion == 2.0)

        // Delete the pricing unit
        context.delete(pricingUnit)
        try context.save()

        // Expected: Price still calculable using stored conversion
        // Price = €4.00 × (2/4) = €2.00
        let price = storeInfo.priceForPurchaseUnit(purchaseUnit)
        #expect(price == Decimal(2.00))
        #expect(storeInfo.pricingUnit == nil)
    }

    @Test("To buy item estimated price")
    func toBuyItemEstimation() async throws {
        let context = try testHelper.makeTestContainer()

        // Setup
        let product = Product(name: "Bread")
        let variant = ProductVariant(product: product, brand: nil, baseUnit: .units)
        let purchaseUnit = PurchaseUnit(unit: .units, conversionToBase: 1, variant: variant)
        let store = Store(name: "Test Store")
        let storeInfo = StoreVariantInfo(
            variant: variant,
            store: store,
            pricePerUnit: Decimal(string: "1.50")!,
            pricingUnit: purchaseUnit
        )

        let item = ToBuyItem(
            storeVariantInfo: storeInfo,
            quantity: "3",
            purchaseUnit: purchaseUnit
        )

        context.insert(product)
        context.insert(variant)
        context.insert(purchaseUnit)
        context.insert(store)
        context.insert(storeInfo)
        context.insert(item)
        try context.save()

        // Expected: 3 × €1.50 = €4.50
        let estimatedPrice = item.estimatedPrice
        #expect(estimatedPrice == Decimal(string: "4.50")!)
    }
}

// MARK: - Unit Display Tests

@Suite("Unit Display")
struct UnitDisplayTests {

    @Test("Standard direction display")
    func standardConversionDisplay() {
        // Test: 150 purchase units = 1 base unit
        let display = PurchaseUnit.formatConversion(
            conversionToBase: 150,
            baseUnitSymbol: "g",
            purchaseUnitSymbol: "units",
            isInverted: false
        )

        // Expected: "1 g = 150 units"
        #expect(display == "1 g = 150 units")
    }

    @Test("Inverted direction display")
    func invertedConversionDisplay() {
        // Test: 1 purchase unit = 800 base units (stored as 0.00125)
        let display = PurchaseUnit.formatConversion(
            conversionToBase: 0.00125,
            baseUnitSymbol: "g",
            purchaseUnitSymbol: "bottle",
            isInverted: true
        )

        // Expected: "1 bottle = 800 g"
        #expect(display == "1 bottle = 800 g")
    }
}

// MARK: - Data Integrity Tests

@Suite("Data Integrity")
struct DataIntegrityTests {
    let testHelper = BuyThatTests()

    @Test("Product deletion cascades to variants")
    func productCascade() async throws {
        let context = try testHelper.makeTestContainer()

        // Create product with 2 variants
        let product = Product(name: "Coffee")
        let variant1 = ProductVariant(product: product, brand: nil, baseUnit: .kilograms)
        let variant2 = ProductVariant(product: product, brand: nil, baseUnit: .kilograms)

        context.insert(product)
        context.insert(variant1)
        context.insert(variant2)
        try context.save()

        // Get persistent IDs
        let variant1ID = variant1.persistentModelID
        let variant2ID = variant2.persistentModelID

        // Delete product
        context.delete(product)
        try context.save()

        // Verify variants are deleted - they should not be in the context anymore
        // Use a fetch descriptor to check if variants exist
        let descriptor1 = FetchDescriptor<ProductVariant>(
            predicate: #Predicate { $0.persistentModelID == variant1ID }
        )
        let descriptor2 = FetchDescriptor<ProductVariant>(
            predicate: #Predicate { $0.persistentModelID == variant2ID }
        )

        let fetchedVariants1 = try context.fetch(descriptor1)
        let fetchedVariants2 = try context.fetch(descriptor2)

        #expect(fetchedVariants1.isEmpty)
        #expect(fetchedVariants2.isEmpty)
    }

    @Test("Variant deletion cascades to purchase units and store info")
    func variantCascade() async throws {
        let context = try testHelper.makeTestContainer()

        // Create variant with purchase units and store info
        let product = Product(name: "Tea")
        let variant = ProductVariant(product: product, brand: nil, baseUnit: .kilograms)
        let purchaseUnit = PurchaseUnit(unit: .kilograms, conversionToBase: 100, variant: variant)
        let store = Store(name: "Test Store")
        let storeInfo = StoreVariantInfo(variant: variant, store: store)

        context.insert(product)
        context.insert(variant)
        context.insert(purchaseUnit)
        context.insert(store)
        context.insert(storeInfo)
        try context.save()

        // Get persistent IDs
        let purchaseUnitID = purchaseUnit.persistentModelID
        let storeInfoID = storeInfo.persistentModelID

        // Delete variant
        context.delete(variant)
        try context.save()

        // Verify cascade deletion using fetch descriptors
        let purchaseDescriptor = FetchDescriptor<PurchaseUnit>(
            predicate: #Predicate { $0.persistentModelID == purchaseUnitID }
        )
        let storeInfoDescriptor = FetchDescriptor<StoreVariantInfo>(
            predicate: #Predicate { $0.persistentModelID == storeInfoID }
        )

        let fetchedPurchaseUnits = try context.fetch(purchaseDescriptor)
        let fetchedStoreInfos = try context.fetch(storeInfoDescriptor)

        #expect(fetchedPurchaseUnits.isEmpty)
        #expect(fetchedStoreInfos.isEmpty)
    }

    @Test("Purchase unit deletion nullifies references")
    func purchaseUnitNullify() async throws {
        let context = try testHelper.makeTestContainer()

        // Create to buy item with purchase unit
        let product = Product(name: "Rice")
        let variant = ProductVariant(product: product, brand: nil, baseUnit: .kilograms)
        let purchaseUnit = PurchaseUnit(unit: .kilograms, conversionToBase: 1000, variant: variant)
        let store = Store(name: "Test Store")
        let storeInfo = StoreVariantInfo(variant: variant, store: store)
        let item = ToBuyItem(
            storeVariantInfo: storeInfo,
            quantity: "2",
            purchaseUnit: purchaseUnit
        )

        context.insert(product)
        context.insert(variant)
        context.insert(purchaseUnit)
        context.insert(store)
        context.insert(storeInfo)
        context.insert(item)
        try context.save()

        // Delete purchase unit
        context.delete(purchaseUnit)
        try context.save()

        // Verify to buy item still exists but reference is nullified
        #expect(item.purchaseUnit == nil)
        #expect(item.quantity == "2")
        #expect(item.storeVariantInfo != nil)
    }
}

// MARK: - Edge Case Tests

@Suite("Edge Cases")
struct EdgeCaseTests {
    let testHelper = BuyThatTests()

    @Test("Invalid quantity string returns nil price")
    func invalidQuantity() async throws {
        let context = try testHelper.makeTestContainer()

        let product = Product(name: "Pasta")
        let variant = ProductVariant(product: product, brand: nil, baseUnit: .kilograms)
        let store = Store(name: "Test Store")
        let storeInfo = StoreVariantInfo(
            variant: variant,
            store: store,
            pricePerUnit: Decimal(2.00)
        )
        let item = ToBuyItem(
            storeVariantInfo: storeInfo,
            quantity: "abc"
        )

        context.insert(product)
        context.insert(variant)
        context.insert(store)
        context.insert(storeInfo)
        context.insert(item)
        try context.save()

        // Expected: nil price for invalid quantity
        #expect(item.estimatedPrice == nil)
    }

    @Test("Zero conversion factor handling")
    func zeroConversionFactor() async throws {
        let context = try testHelper.makeTestContainer()

        let product = Product(name: "Test Product")
        let variant = ProductVariant(product: product, brand: nil, baseUnit: .units)

        // Create purchase unit with zero conversion (edge case)
        let purchaseUnit = PurchaseUnit(unit: .units, conversionToBase: 0, variant: variant)
        let store = Store(name: "Test Store")
        let storeInfo = StoreVariantInfo(
            variant: variant,
            store: store,
            pricePerUnit: Decimal(10.00),
            pricingUnit: purchaseUnit
        )

        context.insert(product)
        context.insert(variant)
        context.insert(purchaseUnit)
        context.insert(store)
        context.insert(storeInfo)
        try context.save()

        // This will cause division by zero - the result should be .infinity or .nan
        // We just verify it doesn't crash
        let price = storeInfo.priceForPurchaseUnit(purchaseUnit)
        #expect(price != nil) // Function completes without crash
    }

    @Test("Display name generation")
    func displayNames() {
        // Test with brand
        let brand = Brand(name: "Brand X")
        let product1 = Product(name: "Milk")
        let variant1 = ProductVariant(product: product1, brand: brand, baseUnit: .liters)

        #expect(variant1.displayName == "Brand X Milk")

        // Test without brand
        let product2 = Product(name: "Bread")
        let variant2 = ProductVariant(product: product2, brand: nil, baseUnit: .units)

        #expect(variant2.displayName == "Bread")

        // Test with brand and detail
        let variant3 = ProductVariant(product: product1, brand: brand, detail: "Organic", baseUnit: .liters)

        #expect(variant3.displayName == "Brand X Organic Milk")
    }
}

// MARK: - Model Basics Tests

@Suite("Model Basics")
struct ModelBasicsTests {

    @Test("Default values set correctly")
    func modelDefaults() {
        // Test ToBuyItem defaults
        let item = ToBuyItem(storeVariantInfo: nil, quantity: "1")
        #expect(item.dateAdded <= Date())

        // Test ProductVariant defaults
        let product = Product(name: "Test")
        let variant = ProductVariant(product: product)
        #expect(variant.baseUnit == .units)
        #expect(variant.dateCreated <= Date())
        #expect(variant.dateModified <= Date())

        // Test Product defaults
        #expect(product.dateCreated <= Date())
        #expect(product.dateModified <= Date())
    }

    @Test("StoreVariantInfo preserves pricing conversion")
    func preserveConversion() {
        let product = Product(name: "Juice")
        let variant = ProductVariant(product: product, brand: nil, baseUnit: .liters)
        let store = Store(name: "Test Store")
        let pricingUnit = PurchaseUnit(unit: .liters, conversionToBase: 2.5, variant: variant)

        // StoreVariantInfo should store the conversion factor on init
        let storeInfo = StoreVariantInfo(
            variant: variant,
            store: store,
            pricePerUnit: Decimal(5.00),
            pricingUnit: pricingUnit
        )

        #expect(storeInfo.pricingUnitConversion == 2.5)
        #expect(storeInfo.pricingUnit === pricingUnit)
    }
}

// MARK: - Merge Quantity Tests

@Suite("Merge Quantities")
struct MergeQuantityTests {

    @Test("Integer addition")
    func integerAddition() {
        #expect(MergeHelper.mergeQuantities("2", "3") == "5")
    }

    @Test("Decimal addition")
    func decimalAddition() {
        #expect(MergeHelper.mergeQuantities("1.5", "2") == "3.5")
    }

    @Test("Decimal result stays decimal")
    func decimalResult() {
        #expect(MergeHelper.mergeQuantities("1.5", "2.3") == "3.8")
    }

    @Test("Whole result from decimals formats as integer")
    func wholeFromDecimals() {
        #expect(MergeHelper.mergeQuantities("1.5", "2.5") == "4")
    }

    @Test("Non-numeric first quantity falls back to concatenation")
    func nonNumericFirst() {
        #expect(MergeHelper.mergeQuantities("some", "2") == "some+2")
    }

    @Test("Non-numeric second quantity falls back to concatenation")
    func nonNumericSecond() {
        #expect(MergeHelper.mergeQuantities("2", "lots") == "2+lots")
    }

    @Test("Both non-numeric falls back to concatenation")
    func bothNonNumeric() {
        #expect(MergeHelper.mergeQuantities("some", "more") == "some+more")
    }

    @Test("Zero quantities")
    func zeroQuantities() {
        #expect(MergeHelper.mergeQuantities("0", "5") == "5")
    }
}

// MARK: - Merge Match Tests

@Suite("Merge Item Matching")
struct MergeMatchTests {
    let testHelper = BuyThatTests()

    @Test("Matches at store-level with same StoreVariantInfo and PurchaseUnit")
    func storeLevelMatch() async throws {
        let context = try testHelper.makeTestContainer()

        let product = Product(name: "Milk")
        let variant = ProductVariant(product: product, brand: nil, baseUnit: .liters)
        let purchaseUnit = PurchaseUnit(unit: .liters, conversionToBase: 1, variant: variant)
        let store = Store(name: "Store A")
        let storeInfo = StoreVariantInfo(variant: variant, store: store)

        let existingItem = ToBuyItem(storeVariantInfo: storeInfo, quantity: "2", purchaseUnit: purchaseUnit)

        let entry = ItemListEntry(storeVariantInfo: storeInfo, quantity: "3", purchaseUnit: purchaseUnit)

        context.insert(product)
        context.insert(variant)
        context.insert(purchaseUnit)
        context.insert(store)
        context.insert(storeInfo)
        context.insert(existingItem)
        context.insert(entry)
        try context.save()

        let match = MergeHelper.findMatch(for: entry, in: [existingItem])
        #expect(match === existingItem)
    }

    @Test("No match when StoreVariantInfo differs")
    func storeLevelNoMatchDifferentStore() async throws {
        let context = try testHelper.makeTestContainer()

        let product = Product(name: "Milk")
        let variant = ProductVariant(product: product, brand: nil, baseUnit: .liters)
        let storeA = Store(name: "Store A")
        let storeB = Store(name: "Store B")
        let storeInfoA = StoreVariantInfo(variant: variant, store: storeA)
        let storeInfoB = StoreVariantInfo(variant: variant, store: storeB)

        let existingItem = ToBuyItem(storeVariantInfo: storeInfoA, quantity: "2")
        let entry = ItemListEntry(storeVariantInfo: storeInfoB, quantity: "3")

        context.insert(product)
        context.insert(variant)
        context.insert(storeA)
        context.insert(storeB)
        context.insert(storeInfoA)
        context.insert(storeInfoB)
        context.insert(existingItem)
        context.insert(entry)
        try context.save()

        let match = MergeHelper.findMatch(for: entry, in: [existingItem])
        #expect(match == nil)
    }

    @Test("Matches at variant-level when neither has StoreVariantInfo")
    func variantLevelMatch() async throws {
        let context = try testHelper.makeTestContainer()

        let product = Product(name: "Bread")
        let variant = ProductVariant(product: product, brand: nil, baseUnit: .units)

        let existingItem = ToBuyItem(variant: variant, quantity: "1")
        let entry = ItemListEntry(variant: variant, quantity: "2")

        context.insert(product)
        context.insert(variant)
        context.insert(existingItem)
        context.insert(entry)
        try context.save()

        let match = MergeHelper.findMatch(for: entry, in: [existingItem])
        #expect(match === existingItem)
    }

    @Test("No variant-level match when existing item has StoreVariantInfo")
    func noVariantMatchWhenExistingHasStore() async throws {
        let context = try testHelper.makeTestContainer()

        let product = Product(name: "Bread")
        let variant = ProductVariant(product: product, brand: nil, baseUnit: .units)
        let store = Store(name: "Store A")
        let storeInfo = StoreVariantInfo(variant: variant, store: store)

        // Existing item has store info, entry does not
        let existingItem = ToBuyItem(storeVariantInfo: storeInfo, quantity: "1")
        let entry = ItemListEntry(variant: variant, quantity: "2")

        context.insert(product)
        context.insert(variant)
        context.insert(store)
        context.insert(storeInfo)
        context.insert(existingItem)
        context.insert(entry)
        try context.save()

        let match = MergeHelper.findMatch(for: entry, in: [existingItem])
        #expect(match == nil)
    }

    @Test("Matches at product-level when neither has variant or StoreVariantInfo")
    func productLevelMatch() async throws {
        let context = try testHelper.makeTestContainer()

        let product = Product(name: "Eggs")

        let existingItem = ToBuyItem(product: product, quantity: "6")
        let entry = ItemListEntry(product: product, quantity: "6")

        context.insert(product)
        context.insert(existingItem)
        context.insert(entry)
        try context.save()

        let match = MergeHelper.findMatch(for: entry, in: [existingItem])
        #expect(match === existingItem)
    }

    @Test("No product-level match when existing item has variant")
    func noProductMatchWhenExistingHasVariant() async throws {
        let context = try testHelper.makeTestContainer()

        let product = Product(name: "Eggs")
        let variant = ProductVariant(product: product, brand: nil, baseUnit: .units)

        let existingItem = ToBuyItem(variant: variant, quantity: "6")
        let entry = ItemListEntry(product: product, quantity: "6")

        context.insert(product)
        context.insert(variant)
        context.insert(existingItem)
        context.insert(entry)
        try context.save()

        let match = MergeHelper.findMatch(for: entry, in: [existingItem])
        #expect(match == nil)
    }

    @Test("No match when PurchaseUnits differ at store level")
    func storeLevelNoMatchDifferentPurchaseUnit() async throws {
        let context = try testHelper.makeTestContainer()

        let product = Product(name: "Milk")
        let variant = ProductVariant(product: product, brand: nil, baseUnit: .liters)
        let unitA = PurchaseUnit(unit: .liters, conversionToBase: 1, variant: variant)
        let unitB = PurchaseUnit(unit: .liters, conversionToBase: 2, variant: variant)
        let store = Store(name: "Store A")
        let storeInfo = StoreVariantInfo(variant: variant, store: store)

        let existingItem = ToBuyItem(storeVariantInfo: storeInfo, quantity: "2", purchaseUnit: unitA)
        let entry = ItemListEntry(storeVariantInfo: storeInfo, quantity: "3", purchaseUnit: unitB)

        context.insert(product)
        context.insert(variant)
        context.insert(unitA)
        context.insert(unitB)
        context.insert(store)
        context.insert(storeInfo)
        context.insert(existingItem)
        context.insert(entry)
        try context.save()

        let match = MergeHelper.findMatch(for: entry, in: [existingItem])
        #expect(match == nil)
    }
}

// MARK: - ItemList Cascade Delete Tests

@Suite("ItemList Data Integrity")
struct ItemListIntegrityTests {
    let testHelper = BuyThatTests()

    @Test("ItemList deletion cascades to entries")
    func itemListCascade() async throws {
        let context = try testHelper.makeTestContainer()

        let list = ItemList(name: "Weekly")
        let entry1 = ItemListEntry(quantity: "1", list: list)
        let entry2 = ItemListEntry(quantity: "2", list: list)

        context.insert(list)
        context.insert(entry1)
        context.insert(entry2)
        try context.save()

        let entry1ID = entry1.persistentModelID
        let entry2ID = entry2.persistentModelID

        context.delete(list)
        try context.save()

        let descriptor1 = FetchDescriptor<ItemListEntry>(
            predicate: #Predicate { $0.persistentModelID == entry1ID }
        )
        let descriptor2 = FetchDescriptor<ItemListEntry>(
            predicate: #Predicate { $0.persistentModelID == entry2ID }
        )

        let fetched1 = try context.fetch(descriptor1)
        let fetched2 = try context.fetch(descriptor2)

        #expect(fetched1.isEmpty)
        #expect(fetched2.isEmpty)
    }
}

struct BuyThatTests {}

// MARK: - MeasurementUnit Tests

@Suite("MeasurementUnit Families and Conversion")
struct MeasurementUnitTests {

    @Test("Family detection for mass units")
    func massFamily() {
        #expect(MeasurementUnit.grams.family == .mass)
        #expect(MeasurementUnit.kilograms.family == .mass)
    }

    @Test("Family detection for volume units")
    func volumeFamily() {
        #expect(MeasurementUnit.milliliters.family == .volume)
        #expect(MeasurementUnit.liters.family == .volume)
    }

    @Test("Family detection for count")
    func countFamily() {
        #expect(MeasurementUnit.units.family == .count)
    }

    @Test("Same-family conversion factor kg to g")
    func kgToGrams() {
        let factor = MeasurementUnit.kilograms.conversionFactor(to: .grams)
        #expect(factor == 1000)
    }

    @Test("Same-family conversion factor g to kg")
    func gramsToKg() {
        let factor = MeasurementUnit.grams.conversionFactor(to: .kilograms)
        #expect(factor == 0.001)
    }

    @Test("Same-family conversion factor L to mL")
    func litersToMl() {
        let factor = MeasurementUnit.liters.conversionFactor(to: .milliliters)
        #expect(factor == 1000)
    }

    @Test("Same-family conversion factor mL to L")
    func mlToLiters() {
        let factor = MeasurementUnit.milliliters.conversionFactor(to: .liters)
        #expect(factor == 0.001)
    }

    @Test("Same unit conversion factor is 1")
    func sameUnitConversion() {
        #expect(MeasurementUnit.kilograms.conversionFactor(to: .kilograms) == 1)
        #expect(MeasurementUnit.grams.conversionFactor(to: .grams) == 1)
        #expect(MeasurementUnit.units.conversionFactor(to: .units) == 1)
    }

    @Test("Cross-family conversion returns nil")
    func crossFamilyConversion() {
        #expect(MeasurementUnit.kilograms.conversionFactor(to: .liters) == nil)
        #expect(MeasurementUnit.grams.conversionFactor(to: .milliliters) == nil)
        #expect(MeasurementUnit.units.conversionFactor(to: .kilograms) == nil)
        #expect(MeasurementUnit.liters.conversionFactor(to: .grams) == nil)
    }

    @Test("Display labels are set")
    func displayLabels() {
        #expect(MeasurementUnit.grams.displayLabel == "Grams (g)")
        #expect(MeasurementUnit.kilograms.displayLabel == "Kilograms (kg)")
        #expect(MeasurementUnit.milliliters.displayLabel == "Milliliters (mL)")
        #expect(MeasurementUnit.liters.displayLabel == "Liters (L)")
        #expect(MeasurementUnit.units.displayLabel == "Count (units)")
    }

    @Test("toFamilyBase values")
    func toFamilyBaseValues() {
        #expect(MeasurementUnit.grams.toFamilyBase == 1)
        #expect(MeasurementUnit.kilograms.toFamilyBase == 1000)
        #expect(MeasurementUnit.milliliters.toFamilyBase == 1)
        #expect(MeasurementUnit.liters.toFamilyBase == 1000)
        #expect(MeasurementUnit.units.toFamilyBase == 1)
    }
}

// MARK: - Unit Name and PurchaseUnit Display Tests

@Suite("Unit Name Integration")
struct ContainerTypeTests {
    let testHelper = BuyThatTests()

    @Test("PurchaseUnit displayName without unitName returns unit symbol")
    func displayNameWithoutContainer() {
        let product = Product(name: "Milk")
        let variant = ProductVariant(product: product, brand: nil, baseUnit: .liters)
        let pu = PurchaseUnit(unit: .liters, conversionToBase: 1, variant: variant)

        #expect(pu.displayName == "L")
    }

    @Test("PurchaseUnit displayName with unitName returns custom name")
    func displayNameWithContainer() async throws {
        let context = try testHelper.makeTestContainer()

        let product = Product(name: "Milk")
        let variant = ProductVariant(product: product, brand: nil, baseUnit: .liters)
        let pu = PurchaseUnit(unit: .units, conversionToBase: 1, variant: variant)
        pu.unitName = "bottle"

        context.insert(product)
        context.insert(variant)
        context.insert(pu)
        try context.save()

        #expect(pu.displayName == "bottle")
    }

    @Test("PurchaseUnit displayWithConversion uses unitName")
    func displayWithConversionUsesContainer() async throws {
        let context = try testHelper.makeTestContainer()

        let product = Product(name: "Juice")
        let variant = ProductVariant(product: product, brand: nil, baseUnit: .liters)
        let pu = PurchaseUnit(unit: .units, conversionToBase: 0.5, isInverted: true, variant: variant)
        pu.unitName = "carton"

        context.insert(product)
        context.insert(variant)
        context.insert(pu)
        try context.save()

        #expect(pu.displayWithConversion == "1 carton = 2 L")
    }

    @Test("Price conversion works with new unit types")
    func priceConversionWithGrams() async throws {
        let context = try testHelper.makeTestContainer()

        let product = Product(name: "Spice")
        let variant = ProductVariant(product: product, brand: nil, baseUnit: .grams)

        // Pricing unit: 100g packet (conversionToBase = 0.01, i.e., 0.01 packets = 1g)
        let pricingUnit = PurchaseUnit(unit: .grams, conversionToBase: 0.01, variant: variant)

        // Purchase unit: 50g packet (conversionToBase = 0.02, i.e., 0.02 packets = 1g)
        let purchaseUnit = PurchaseUnit(unit: .grams, conversionToBase: 0.02, variant: variant)

        let store = Store(name: "Test Store")

        let storeInfo = StoreVariantInfo(
            variant: variant,
            store: store,
            pricePerUnit: Decimal(string: "5.00")!,
            pricingUnit: pricingUnit
        )

        context.insert(product)
        context.insert(variant)
        context.insert(pricingUnit)
        context.insert(purchaseUnit)
        context.insert(store)
        context.insert(storeInfo)
        try context.save()

        // Price per 50g = 5.00 * (0.01 / 0.02) = 2.50
        let price = storeInfo.priceForPurchaseUnit(purchaseUnit)
        #expect(price == Decimal(string: "2.50")!)
    }

    @Test("PurchaseUnit unitName can be cleared, falls back to unit symbol")
    func containerTypeDeletionNullifies() async throws {
        let context = try testHelper.makeTestContainer()

        let product = Product(name: "Water")
        let variant = ProductVariant(product: product, brand: nil, baseUnit: .liters)
        let pu = PurchaseUnit(unit: .units, conversionToBase: 1, variant: variant)
        pu.unitName = "bottle"

        context.insert(product)
        context.insert(variant)
        context.insert(pu)
        try context.save()

        #expect(pu.unitName != nil)
        #expect(pu.displayName == "bottle")

        pu.unitName = nil
        try context.save()

        #expect(pu.unitName == nil)
        #expect(pu.displayName == "unit") // Falls back to unit.singularSymbol
    }
}
