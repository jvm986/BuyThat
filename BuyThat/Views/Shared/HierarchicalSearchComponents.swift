//
//  HierarchicalSearchComponents.swift
//  BuyThat
//
//  Created by Claude on 08.12.25.
//

import SwiftUI
import SwiftData

// MARK: - Shared Data Structures

struct ProductGroup: Identifiable {
    let id: PersistentIdentifier
    let product: Product
    var variants: [VariantGroup]
}

struct VariantGroup: Identifiable {
    let id: PersistentIdentifier
    let variant: ProductVariant
    var storeItems: [StoreVariantInfo]
}

// MARK: - Hierarchical Results Builder

struct HierarchicalResultsBuilder {
    static func build(
        products: [Product],
        variants: [ProductVariant],
        storeInfos: [StoreVariantInfo]
    ) -> [ProductGroup] {
        // Build a map of products
        var productMap: [PersistentIdentifier: ProductGroup] = [:]

        // First, add all matching products
        for product in products {
            productMap[product.persistentModelID] = ProductGroup(
                id: product.persistentModelID,
                product: product,
                variants: []
            )
        }

        // Build a map of variants by product
        var variantsByProduct: [PersistentIdentifier: [VariantGroup]] = [:]
        for variant in variants {
            guard let product = variant.product else { continue }

            let variantGroup = VariantGroup(
                id: variant.persistentModelID,
                variant: variant,
                storeItems: []
            )

            if variantsByProduct[product.persistentModelID] == nil {
                variantsByProduct[product.persistentModelID] = []
            }
            variantsByProduct[product.persistentModelID]?.append(variantGroup)

            // Also ensure the product is in the map
            if productMap[product.persistentModelID] == nil {
                productMap[product.persistentModelID] = ProductGroup(
                    id: product.persistentModelID,
                    product: product,
                    variants: []
                )
            }
        }

        // Group store items by variant
        var storeItemsByVariant: [PersistentIdentifier: [StoreVariantInfo]] = [:]
        for storeInfo in storeInfos {
            guard let variant = storeInfo.variant else { continue }

            if storeItemsByVariant[variant.persistentModelID] == nil {
                storeItemsByVariant[variant.persistentModelID] = []
            }
            storeItemsByVariant[variant.persistentModelID]?.append(storeInfo)

            // Ensure variant exists
            if variantsByProduct[variant.product?.persistentModelID ?? variant.persistentModelID] == nil {
                variantsByProduct[variant.product?.persistentModelID ?? variant.persistentModelID] = []
            }

            // Check if this variant is already in the list
            let productID = variant.product?.persistentModelID ?? variant.persistentModelID
            let existingVariantIndex = variantsByProduct[productID]?.firstIndex { $0.id == variant.persistentModelID }

            if existingVariantIndex == nil {
                variantsByProduct[productID]?.append(VariantGroup(
                    id: variant.persistentModelID,
                    variant: variant,
                    storeItems: []
                ))
            }

            // Ensure product exists
            if let product = variant.product, productMap[product.persistentModelID] == nil {
                productMap[product.persistentModelID] = ProductGroup(
                    id: product.persistentModelID,
                    product: product,
                    variants: []
                )
            }
        }

        // Assemble the hierarchy
        var results: [ProductGroup] = []
        for (productID, var productGroup) in productMap {
            // Add variants to this product
            if let variants = variantsByProduct[productID] {
                productGroup.variants = variants.map { var vg = $0
                    // Add store items to each variant
                    vg.storeItems = storeItemsByVariant[vg.id] ?? []
                    return vg
                }
            }
            results.append(productGroup)
        }

        // Sort by product name
        return results.sorted { $0.product.name < $1.product.name }
    }
}

// MARK: - Configurable Row Components

enum RowActionStyle {
    case select // For selection (no icon prefix)
    case quickAdd // For quick add (plus icon prefix)
}

struct HierarchicalProductRow: View {
    let product: Product
    let style: RowActionStyle
    let onAction: () -> Void

    var body: some View {
        Button(action: onAction) {
            HStack {
                if style == .quickAdd {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.orange)
                }
                Text(product.name)
                    .foregroundStyle(.primary)
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "square.grid.2x2.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }
}

struct HierarchicalVariantRow: View {
    let variant: ProductVariant
    let style: RowActionStyle
    let onAction: () -> Void

    var body: some View {
        Button(action: onAction) {
            HStack {
                Image(systemName: "arrow.turn.down.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if style == .quickAdd {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.blue)
                }
                Text(variant.displayNameShort)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "shippingbox.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
    }
}

struct HierarchicalStoreInfoRow: View {
    let storeInfo: StoreVariantInfo
    let style: RowActionStyle
    let onAction: () -> Void

    var body: some View {
        Button(action: onAction) {
            HStack {
                Image(systemName: "arrow.turn.down.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 16)
                if style == .quickAdd {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.green)
                }
                VStack(alignment: .leading) {
                    Text(storeInfo.store?.name ?? "Unknown Store")
                        .foregroundStyle(.primary)
                    if let price = storeInfo.formattedPrice {
                        Text(price)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "tag.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
    }
}

// MARK: - Hierarchical Group Views

struct HierarchicalProductGroupView: View {
    let productGroup: ProductGroup
    let style: RowActionStyle
    let onSelectProduct: (Product) -> Void
    let onSelectVariant: (ProductVariant) -> Void
    let onSelectStoreInfo: (StoreVariantInfo) -> Void

    var body: some View {
        HierarchicalProductRow(
            product: productGroup.product,
            style: style,
            onAction: { onSelectProduct(productGroup.product) }
        )

        ForEach(productGroup.variants) { variantGroup in
            HierarchicalVariantGroupView(
                variantGroup: variantGroup,
                style: style,
                onSelectVariant: onSelectVariant,
                onSelectStoreInfo: onSelectStoreInfo
            )
        }
    }
}

struct HierarchicalVariantGroupView: View {
    let variantGroup: VariantGroup
    let style: RowActionStyle
    let onSelectVariant: (ProductVariant) -> Void
    let onSelectStoreInfo: (StoreVariantInfo) -> Void

    var body: some View {
        HierarchicalVariantRow(
            variant: variantGroup.variant,
            style: style,
            onAction: { onSelectVariant(variantGroup.variant) }
        )

        ForEach(variantGroup.storeItems) { storeInfo in
            HierarchicalStoreInfoRow(
                storeInfo: storeInfo,
                style: style,
                onAction: { onSelectStoreInfo(storeInfo) }
            )
        }
    }
}

// MARK: - Complete Hierarchical Results View

struct HierarchicalSearchResultsView: View {
    let hierarchicalResults: [ProductGroup]
    let style: RowActionStyle
    let onSelectProduct: (Product) -> Void
    let onSelectVariant: (ProductVariant) -> Void
    let onSelectStoreInfo: (StoreVariantInfo) -> Void
    let onCreateNew: () -> Void

    var body: some View {
        ForEach(hierarchicalResults) { productGroup in
            Section {
                HierarchicalProductGroupView(
                    productGroup: productGroup,
                    style: style,
                    onSelectProduct: onSelectProduct,
                    onSelectVariant: onSelectVariant,
                    onSelectStoreInfo: onSelectStoreInfo
                )
            }
        }

        Section {
            Button(action: onCreateNew) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Create New Item")
                        .foregroundStyle(.primary)
                }
            }
        }
    }
}
