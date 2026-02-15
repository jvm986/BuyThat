//
//  ReceiptReviewView.swift
//  BuyThat
//

import SwiftUI

struct ReceiptReviewView: View {
    let store: Store
    let receiptDate: Date?
    @Binding var items: [MatchedReceiptItem]
    let onSave: () -> Void

    @State private var navigateToNewItem = false
    @State private var newItemIndex: Int?

    private var matchedCount: Int {
        items.filter(\.isMatched).count
    }

    private var unmatchedCount: Int {
        items.filter { !$0.isMatched }.count
    }

    private var includedCount: Int {
        items.filter(\.isIncluded).count
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Store") {
                    Text(store.name)
                }
                if let date = receiptDate {
                    LabeledContent("Date") {
                        Text(dateFormatter.string(from: date))
                    }
                }
                LabeledContent("Items") {
                    Text("\(items.count) total")
                }
            } header: {
                Text("Receipt Summary")
            }

            Section {
                HStack(spacing: 16) {
                    Label("\(matchedCount)", systemImage: "circle.fill")
                        .foregroundStyle(.green)
                    Label("\(unmatchedCount)", systemImage: "circle.fill")
                        .foregroundStyle(.red)
                    Spacer()
                    Text("\(includedCount) selected")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }

            Section {
                ForEach($items) { $item in
                    NavigationLink {
                        ReceiptItemDetailView(item: $item, store: store)
                    } label: {
                        ReceiptItemRow(item: $item)
                    }
                }

                Button {
                    let newItem = MatchedReceiptItem(
                        parsedItem: ParsedReceiptItem(),
                        matchResult: .noMatch(suggestedName: "")
                    )
                    items.append(newItem)
                    newItemIndex = items.count - 1
                    navigateToNewItem = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Add Item")
                            .foregroundStyle(.primary)
                    }
                }
            } header: {
                Text("Items")
            }
        }
        .navigationTitle("Review Receipt")
        .navigationDestination(isPresented: $navigateToNewItem) {
            if let index = newItemIndex, index < items.count {
                ReceiptItemDetailView(item: $items[index], store: store)
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    onSave()
                }
                .disabled(includedCount == 0)
            }
        }
    }
}
