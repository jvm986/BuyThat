# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BuyThat is a native iOS shopping list app built with SwiftUI and SwiftData. It helps users track products across different stores with price comparisons and measurement unit conversions.

## Development Commands

### Building and Running
```bash
# Build the project
xcodebuild -scheme BuyThat -configuration Debug build

# Run tests
xcodebuild -scheme BuyThat -configuration Debug test

# Run UI tests
xcodebuild -scheme BuyThat -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15' test
```

### Opening in Xcode
```bash
open BuyThat.xcodeproj
```

## Architecture

### Data Model Hierarchy

The app uses SwiftData with a hierarchical structure:

1. **Base Entities** (lowest level):
   - `Tag`: Categorization labels (e.g., "Organic", "Gluten Free")
   - `Brand`: Product manufacturers
   - `Store`: Shopping locations
   - `MeasurementUnit`: Enum for units (kilograms, liters, units)

2. **Product Layer**:
   - `Product`: Base product type (e.g., "Milk", "Bread")
     - Has many `Tag` relationships
     - Has many `ProductVariant` children (cascade delete)

3. **Variant Layer**:
   - `ProductVariant`: Specific brand/product combination with optional detail (e.g., "Brand A Organic Milk")
     - Belongs to one `Product` and one `Brand`
     - Has optional `detail` field for additional specification
     - Has a `baseUnit` (MeasurementUnit)
     - Has many `PurchaseUnit` children (cascade delete)
     - Has many `StoreVariantInfo` children (cascade delete)
     - Provides both `displayName` (full) and `displayNameShort` (excludes product name)

4. **Purchase Unit Layer**:
   - `PurchaseUnit`: Defines sellable package sizes
     - Belongs to one `ProductVariant`
     - Contains `conversionToBase` factor and `isInverted` flag
     - Example: "1 bottle = 1L" where bottle is the purchase unit
     - Has inverse relationships to `ShoppingListItem` and `StoreVariantInfo`

5. **Store Integration Layer**:
   - `StoreVariantInfo`: Links variants to stores with pricing
     - References `ProductVariant`, `Store`, and optional `PurchaseUnit` (for pricing)
     - Contains `pricePerUnit` (based on the `pricingUnit`)
     - Stores `pricingUnitConversion` to preserve pricing if `pricingUnit` is deleted
     - Complex price conversion logic in `priceForPurchaseUnit()`
     - Has inverse relationship to `ShoppingListItem`

6. **Shopping Lists**:
   - `ShoppingList`: Container for shopping list items
     - Has many `ShoppingListItem` children (cascade delete)
   - `ShoppingListItem`: Individual items on a list with flexible specificity
     - Supports three levels of specificity (only one should be set):
       - `storeVariantInfo`: Full specificity (variant at a specific store with pricing)
       - `variant`: Variant-level (specific brand/detail without store)
       - `product`: Product-level (generic product without variant or store)
     - Contains `quantity` (string), `isPurchased` flag, and optional `purchaseUnit`
     - Provides `effectiveProduct`, `effectiveVariant`, `effectiveStore` computed properties
     - Calculates `estimatedPrice` based on quantity and unit pricing (when store info available)

### Price Conversion Logic

The price conversion system is critical to understand:

- `StoreVariantInfo.pricePerUnit` is always stored relative to `pricingUnit`
- `PurchaseUnit.conversionToBase` stores how many purchase units equal one base unit
- `PurchaseUnit.isInverted` indicates whether user entered "1 purchase = X base" vs "1 base = X purchase"
- Price conversion formula: `price * (sourceFactor / targetFactor)`

Example: If milk base unit is "liters" and you have:
- Pricing unit: 1L bottle (conversionToBase = 1)
- Purchase unit: 0.5L bottle (conversionToBase = 2, meaning 2 bottles = 1L)
- Price per 1L bottle = €2.00
- Price per 0.5L bottle = €2.00 × (1/2) = €1.00

Note: The `pricingUnitConversion` field stores the conversion factor at the time of price entry, allowing price calculations to continue working even if the original `pricingUnit` is deleted.

### View Architecture

Views are organized by purpose:

- **Management Views** (`Views/Management/`): CRUD interfaces for Tags, Brands, Products, ProductVariants, Stores, StoreVariantInfo
- **Form Views** (`Views/Forms/`): Reusable form components for creating/editing entities
  - `ShoppingListItemFormView`: Unified form for adding/editing shopping list items with hierarchical search
  - `CreateNewItemView`: Quick creation of products, variants, or store info from search context
- **Selection Views** (`Views/Selection/`): Picker-style views for selecting entities in forms
- **Shared Components** (`Views/Shared/`):
  - `HierarchicalSearchComponents`: Reusable hierarchical search UI that displays products → variants → store items
  - Supports both selection mode and quick-add mode
- **Shopping List Views** (`Views/ShoppingLists/`): Main UI for shopping lists
  - `ShoppingListsView`: Root view listing all shopping lists
  - `ShoppingListDetailView`: Individual list with hierarchical search and quick-add

### SwiftData Configuration

The app uses a shared `ModelContainer` configured in `BuyThatApp.swift` with all model types registered. The container automatically uses in-memory storage when running UI tests (detected via `UI-TESTING` launch argument). For previews, use `PreviewContainer.sample` which provides in-memory sample data.

### Relationship Delete Rules

Critical delete rules to maintain:
- Products cascade delete to ProductVariants
- ProductVariants cascade delete to PurchaseUnits and StoreVariantInfo
- ShoppingLists cascade delete to ShoppingListItems
- Most other relationships use `.nullify` to prevent cascading
- Note: PurchaseUnits have nullify relationships to ShoppingListItems and StoreVariantInfo to prevent data loss
- StoreVariantInfo stores conversion factors to handle deleted PurchaseUnit references gracefully

## Key Files

- `BuyThat/BuyThatApp.swift`: App entry point with ModelContainer setup
- `BuyThat/PreviewContainer.swift`: Sample data for previews
- `BuyThat/ContentView.swift`: App root (shows ShoppingListsView)
- `BuyThat/Models/`: All SwiftData model definitions
- `BuyThat/Views/`: All SwiftUI views organized by function

## Testing

- Unit tests: `BuyThatTests/BuyThatTests.swift`
- UI tests: `BuyThatUITests/BuyThatUITests.swift` and `BuyThatUITestsLaunchTests.swift`

When writing tests, use in-memory ModelContainers to avoid persisting test data.
