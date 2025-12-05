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
   - `MeasurementUnit`: Enum for units (grams, milliliters, units, etc.)

2. **Product Layer**:
   - `Product`: Base product type (e.g., "Milk", "Bread")
     - Has many `Tag` relationships
     - Has many `ProductVariant` children (cascade delete)

3. **Variant Layer**:
   - `ProductVariant`: Specific brand/product combination (e.g., "Brand A Milk")
     - Belongs to one `Product` and one `Brand`
     - Has a `baseUnit` (MeasurementUnit)
     - Has many `PurchaseUnit` children (cascade delete)
     - Has many `StoreVariantInfo` children (cascade delete)

4. **Purchase Unit Layer**:
   - `PurchaseUnit`: Defines sellable package sizes
     - Belongs to one `ProductVariant`
     - Contains `conversionToBase` factor and `isInverted` flag
     - Example: "1 bottle = 1000ml" where bottle is the purchase unit

5. **Store Integration Layer**:
   - `StoreVariantInfo`: Links variants to stores with pricing
     - References `ProductVariant`, `Store`, and `PurchaseUnit` (for pricing)
     - Contains `pricePerUnit` (based on the `pricingUnit`)
     - Has many `PriceHistory` children (cascade delete)
     - Complex price conversion logic in `priceForPurchaseUnit()`

6. **Shopping Lists**:
   - `ShoppingList`: Container for shopping list items
     - Has many `ShoppingListItem` children (cascade delete)
   - `ShoppingListItem`: Individual items on a list
     - References `StoreVariantInfo` and optional `PurchaseUnit`
     - Contains `quantity` (string), `isPurchased` flag
     - Calculates `estimatedPrice` based on quantity and unit pricing

### Price Conversion Logic

The price conversion system is critical to understand:

- `StoreVariantInfo.pricePerUnit` is always stored relative to `pricingUnit`
- `PurchaseUnit.conversionToBase` stores how many purchase units equal one base unit
- `PurchaseUnit.isInverted` indicates whether user entered "1 purchase = X base" vs "1 base = X purchase"
- Price conversion formula: `price * (sourceFactor / targetFactor)`

Example: If milk base unit is "liters" and you have:
- Pricing unit: 1L bottle (conversionToBase = 1)
- Purchase unit: 500ml bottle (conversionToBase = 2, meaning 2 bottles = 1L)
- Price per 1L bottle = €2.00
- Price per 500ml bottle = €2.00 × (1/2) = €1.00

### View Architecture

Views are organized by purpose:

- **Management Views** (`Views/Management/`): CRUD interfaces for Tags, Brands, Products, ProductVariants, Stores, StoreVariantInfo
- **Form Views** (`Views/Forms/`): Reusable form components for creating/editing entities
- **Selection Views** (`Views/Selection/`): Picker-style views for selecting entities in forms
- **Shopping List Views** (`Views/ShoppingLists/`): Main UI for shopping lists
  - `ShoppingListsView`: Root view listing all shopping lists
  - `ShoppingListDetailView`: Individual list with items
  - `AddShoppingListItemView` / `EditShoppingListItemView`: Item management

### SwiftData Configuration

The app uses a shared `ModelContainer` configured in `BuyThatApp.swift` with all model types registered. For previews, use `PreviewContainer.sample` which provides in-memory sample data.

### Relationship Delete Rules

Critical delete rules to maintain:
- Products cascade delete to ProductVariants
- ProductVariants cascade delete to PurchaseUnits and StoreVariantInfo
- StoreVariantInfo cascade deletes to PriceHistory
- ShoppingLists cascade delete to ShoppingListItems
- Most other relationships use `.nullify` to prevent cascading

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
