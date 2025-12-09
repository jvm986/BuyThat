# BuyThat

A native iOS shopping list app with price comparison and smart unit conversion. Track products across different stores, compare prices per unit, and manage shopping lists with automatic price estimates.

## Technical Stack

- **Language**: Swift 6.0
- **Framework**: SwiftUI
- **Minimum iOS**: 17.0
- **Persistence**: SwiftData
- **Architecture**: MVVM with SwiftData models
- **Testing**: XCTest unit and UI tests

## Testing

```bash
# All tests
xcodebuild test -project BuyThat.xcodeproj -scheme BuyThat -destination 'platform=iOS Simulator,name=iPhone 15'

# Unit tests only
xcodebuild test -project BuyThat.xcodeproj -scheme BuyThat -only-testing:BuyThatTests -destination 'platform=iOS Simulator,name=iPhone 15'

# UI tests only
xcodebuild test -project BuyThat.xcodeproj -scheme BuyThat -only-testing:BuyThatUITests -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Requirements

- Xcode 16.0+
- iOS 17.0+
- Swift 6.0+

## Features

- **Flexible Shopping Lists**: Add items at any specificity level (generic product, specific brand variant, or store-specific with pricing)
- **Hierarchical Search**: Smart search with grouped results showing products → variants → store items
- **Price Comparison**: Track prices across different stores and units
- **Unit Conversion**: Automatic conversion between different package sizes (bottles, boxes, etc.)
- **Quick Add**: Add items directly from search results at any hierarchy level

## Architecture

The app uses SwiftData for persistence with a hierarchical model structure:

### Data Model Hierarchy

1. **Base Entities**:
   - **Tag**: Categorization labels (e.g., "Organic", "Gluten Free")
   - **Brand**: Product manufacturers
   - **Store**: Shopping locations
   - **MeasurementUnit**: Enum for units (kilograms, liters, units)

2. **Product Layer**:
   - **Product**: Base product type (e.g., "Milk", "Bread")
     - Has many Tags
     - Cascade deletes to ProductVariants

3. **Variant Layer**:
   - **ProductVariant**: Specific brand/product combination with optional detail (e.g., "Brand A Organic Milk")
     - References Product and Brand
     - Has optional detail field for additional specification
     - Has baseUnit (MeasurementUnit)
     - Cascade deletes to PurchaseUnits and StoreVariantInfo

4. **Purchase Unit Layer**:
   - **PurchaseUnit**: Defines sellable package sizes
     - Contains conversion factor to base unit
     - Example: "1 bottle = 1L"

5. **Store Integration Layer**:
   - **StoreVariantInfo**: Links variants to stores with pricing
     - References ProductVariant, Store, and optional PurchaseUnit
     - Contains pricePerUnit and stores pricingUnitConversion
     - Preserves pricing even if PurchaseUnit is deleted

6. **Shopping Lists**:
   - **ShoppingList**: Container for shopping list items
   - **ShoppingListItem**: Individual items with quantity and price estimates
     - Supports flexible specificity: can reference StoreVariantInfo (store-specific), ProductVariant (brand-specific), or Product (generic)
     - Optional PurchaseUnit reference for custom quantities

### Price Conversion

The app features smart price conversion across different units:

- Prices stored relative to a pricingUnit
- Automatic conversion between purchase units using conversion factors
- Support for inverted conversions (e.g., "2 bottles per liter" vs "0.5 liters per bottle")
- Dynamic price-per-unit calculations for comparison shopping
