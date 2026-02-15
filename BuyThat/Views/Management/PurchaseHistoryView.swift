//
//  PurchaseHistoryView.swift
//  BuyThat
//

import SwiftUI
import SwiftData

// MARK: - Purchase History List

struct PurchaseHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShoppingTrip.date, order: .reverse) private var trips: [ShoppingTrip]

    var body: some View {
        List {
            if trips.isEmpty {
                ContentUnavailableView(
                    "No Purchase History",
                    systemImage: "cart",
                    description: Text("Shopping trips from scanned receipts will appear here.")
                )
            } else {
                ForEach(trips) { trip in
                    NavigationLink {
                        ShoppingTripDetailView(trip: trip)
                    } label: {
                        ShoppingTripRow(trip: trip)
                    }
                }
                .onDelete(perform: deleteTrips)
            }
        }
        .navigationTitle("Purchase History")
    }

    private func deleteTrips(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(trips[index])
        }
        try? modelContext.save()
    }
}

// MARK: - Shopping Trip Row

struct ShoppingTripRow: View {
    let trip: ShoppingTrip

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(trip.displayStoreName)
                    .fontWeight(.medium)
                Spacer()
                Text(trip.formattedTotal)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text(trip.date, style: .date)
                Spacer()
                Text("\(trip.itemCount) item\(trip.itemCount == 1 ? "" : "s")")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Shopping Trip Detail

struct ShoppingTripDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var trip: ShoppingTrip

    @State private var showingStoreSheet = false

    private var sortedItems: [ShoppingTripItem] {
        (trip.items ?? []).sorted { $0.displayProductName.localizedCaseInsensitiveCompare($1.displayProductName) == .orderedAscending }
    }

    var body: some View {
        List {
            Section("Summary") {
                Button {
                    showingStoreSheet = true
                } label: {
                    LabeledContent("Store") {
                        HStack {
                            Text(trip.displayStoreName)
                                .foregroundStyle(.primary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                DatePicker("Date", selection: $trip.date, displayedComponents: .date)
                    .onChange(of: trip.date) {
                        try? modelContext.save()
                    }

                LabeledContent("Items", value: "\(trip.itemCount)")
                LabeledContent("Total", value: trip.formattedTotal)
            }

            Section("Items") {
                ForEach(sortedItems) { item in
                    NavigationLink {
                        ShoppingTripItemDetailView(item: item, store: trip.store)
                    } label: {
                        ShoppingTripItemRow(item: item)
                    }
                }
                .onDelete(perform: deleteItems)
            }
        }
        .navigationTitle(trip.displayStoreName)
        .sheet(isPresented: $showingStoreSheet) {
            NavigationStack {
                SelectStoreView { store in
                    trip.store = store
                    trip.storeName = store.name
                    try? modelContext.save()
                }
            }
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { sortedItems[$0] }
        for item in itemsToDelete {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}

// MARK: - Shopping Trip Item Row

struct ShoppingTripItemRow: View {
    let item: ShoppingTripItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.displayProductName)
                    .fontWeight(.medium)
                Spacer()
                Text(item.formattedLineTotal)
            }
            HStack {
                Text(item.receiptText)
                    .lineLimit(1)
                Spacer()
                if item.quantity > 1 {
                    Text("\(item.quantity) x \(item.formattedPrice)")
                }
                if let unitPrice = item.formattedUnitPrice {
                    Text(unitPrice)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Shopping Trip Item Detail

struct ShoppingTripItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: ShoppingTripItem
    let store: Store?

    @State private var editedPrice: String
    @State private var editedQuantity: String
    @State private var showingStoreInfoSheet = false

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        return formatter
    }

    init(item: ShoppingTripItem, store: Store?) {
        self.item = item
        self.store = store
        _editedPrice = State(initialValue: "\(item.pricePerItem)")
        _editedQuantity = State(initialValue: "\(item.quantity)")
    }

    var body: some View {
        List {
            Section("Receipt Info") {
                LabeledContent("Receipt Text") {
                    Text(item.receiptText)
                        .foregroundStyle(.secondary)
                }
                if let unitPrice = item.unitPrice, let unitPriceUnit = item.unitPriceUnit {
                    LabeledContent("Unit Price") {
                        Text("\(unitPrice as NSDecimalNumber, formatter: currencyFormatter)/\(unitPriceUnit)")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Store Item") {
                Button {
                    showingStoreInfoSheet = true
                } label: {
                    HStack {
                        if let storeInfo = item.storeVariantInfo {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(storeInfo.variant?.displayName ?? "Unknown")
                                    .foregroundStyle(.primary)
                                if let price = storeInfo.formattedPricePerUnit {
                                    Text(price)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } else if let variant = item.variant {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(variant.displayName)
                                    .foregroundStyle(.primary)
                                Text("No store pricing")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else if let product = item.product {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(product.name)
                                    .foregroundStyle(.primary)
                                Text("Product only")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("Select Store Item")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Section("Price & Quantity") {
                HStack {
                    Text("Price")
                    Spacer()
                    TextField("0.00", text: $editedPrice)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 100)
                        .onChange(of: editedPrice) {
                            let normalized = editedPrice.replacingOccurrences(of: ",", with: ".")
                            if let value = Decimal(string: normalized) {
                                item.pricePerItem = value
                                try? modelContext.save()
                            }
                        }
                }

                HStack {
                    Text("Quantity")
                    Spacer()
                    TextField("1", text: $editedQuantity)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 100)
                        .onChange(of: editedQuantity) {
                            if let value = Int(editedQuantity) {
                                item.quantity = value
                                try? modelContext.save()
                            }
                        }
                }

                LabeledContent("Line Total") {
                    Text(item.formattedLineTotal)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Edit Item")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingStoreInfoSheet) {
            NavigationStack {
                SelectStoreVariantInfoView(filterStore: store) { storeInfo in
                    item.storeVariantInfo = storeInfo
                    item.variant = storeInfo.variant
                    item.product = storeInfo.variant?.product
                    item.productName = storeInfo.variant?.product?.name ?? item.productName
                    try? modelContext.save()
                }
            }
        }
    }
}

// MARK: - Price History

struct PriceHistoryView: View {
    let storeVariantInfo: StoreVariantInfo

    private var sortedItems: [ShoppingTripItem] {
        (storeVariantInfo.shoppingTripItems ?? [])
            .sorted { ($0.trip?.date ?? .distantPast) > ($1.trip?.date ?? .distantPast) }
    }

    var body: some View {
        List {
            if sortedItems.isEmpty {
                ContentUnavailableView(
                    "No Price History",
                    systemImage: "chart.line.downtrend.xyaxis",
                    description: Text("Price history from scanned receipts will appear here.")
                )
            } else {
                ForEach(sortedItems) { item in
                    HStack {
                        if let tripDate = item.trip?.date {
                            Text(tripDate, style: .date)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(item.formattedPrice)
                            if let unitPrice = item.formattedUnitPrice {
                                Text(unitPrice)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Price History")
    }
}

// MARK: - Previews

#Preview("Purchase History") {
    NavigationStack {
        PurchaseHistoryView()
    }
    .modelContainer(PreviewContainer.sample)
}

#Preview("Trip Detail") {
    let container = PreviewContainer.sample
    let context = container.mainContext
    let trips = try! context.fetch(FetchDescriptor<ShoppingTrip>())
    return NavigationStack {
        ShoppingTripDetailView(trip: trips.first!)
    }
    .modelContainer(container)
}
