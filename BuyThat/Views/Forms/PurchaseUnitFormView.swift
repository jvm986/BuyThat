//
//  PurchaseUnitFormView.swift
//  BuyThat
//
//  Created by Claude on 04.12.25.
//

import SwiftUI
import SwiftData

struct PurchaseUnitFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let variant: ProductVariant
    let purchaseUnit: PurchaseUnit?
    let onSave: (PurchaseUnit) -> Void

    @State private var conversionText: String = ""
    @State private var selectedUnit: MeasurementUnit
    @State private var isInverted: Bool = false

    init(variant: ProductVariant, purchaseUnit: PurchaseUnit? = nil, onSave: @escaping (PurchaseUnit) -> Void) {
        self.variant = variant
        self.purchaseUnit = purchaseUnit
        self.onSave = onSave

        if let unit = purchaseUnit {
            _selectedUnit = State(initialValue: unit.unit)

            // If inverted, show the value the user originally entered (1/conversionToBase)
            let displayValue = unit.isInverted ? (1.0 / unit.conversionToBase) : unit.conversionToBase
            let convStr = displayValue.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(displayValue))
                : String(format: "%.5g", displayValue)

            _conversionText = State(initialValue: convStr)
            _isInverted = State(initialValue: unit.isInverted)
        } else {
            _selectedUnit = State(initialValue: variant.baseUnit)
        }
    }

    private var conversion: Double? {
        // Replace comma with period for decimal parsing
        let normalizedText = conversionText.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalizedText), value > 0 else { return nil }
        return isInverted ? (1.0 / value) : value
    }

    private var canSave: Bool {
        conversion != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("Conversion Factor", text: $conversionText)
                            .keyboardType(.decimalPad)

                        Button {
                            flipConversion()
                        } label: {
                            Image(systemName: "arrow.left.arrow.right")
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                    }

                    Picker("Measurement Unit", selection: $selectedUnit) {
                        ForEach([MeasurementUnit.units, .kilograms, .liters], id: \.self) { unit in
                            Text(unit.symbol).tag(unit)
                        }
                    }
                } header: {
                    Text("Measurement")
                } footer: {
                    if isInverted {
                        Text("How many \(variant.baseUnit.symbol) equals 1 \(selectedUnit.symbol)?")
                    } else {
                        Text("How many \(selectedUnit.symbol) equals 1 \(variant.baseUnit.symbol)?")
                    }
                }

                if let conv = conversion {
                    Section {
                        Text(previewText(conv))
                            .foregroundStyle(.secondary)
                    } header: {
                        Text("Preview")
                    }
                }
            }
            .navigationTitle(purchaseUnit == nil ? "Add Purchase Unit" : "Edit Purchase Unit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private func flipConversion() {
        // Convert the existing value when inverting
        // Replace comma with period for decimal parsing
        let normalizedText = conversionText.replacingOccurrences(of: ",", with: ".")
        if let currentValue = Double(normalizedText), currentValue > 0 {
            let invertedValue = 1.0 / currentValue
            conversionText = invertedValue.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(invertedValue))
                : String(format: "%.5g", invertedValue)
        }
        isInverted.toggle()
    }

    private func previewText(_ storedConversion: Double) -> String {
        return PurchaseUnit.formatConversion(
            conversionToBase: storedConversion,
            baseUnitSymbol: variant.baseUnit.symbol,
            purchaseUnitSymbol: selectedUnit.symbol,
            isInverted: isInverted
        )
    }

    private func save() {
        guard let conv = conversion else { return }

        if let existingUnit = purchaseUnit {
            // Update existing purchase unit
            existingUnit.unit = selectedUnit
            existingUnit.conversionToBase = conv
            existingUnit.isInverted = isInverted
            try? modelContext.save()
            onSave(existingUnit)
        } else {
            // Create new purchase unit
            let newUnit = PurchaseUnit(
                unit: selectedUnit,
                conversionToBase: conv,
                isInverted: isInverted,
                variant: variant
            )
            modelContext.insert(newUnit)
            try? modelContext.save()
            onSave(newUnit)
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        PurchaseUnitFormViewPreview()
    }
    .modelContainer(PreviewContainer.sample)
}

private struct PurchaseUnitFormViewPreview: View {
    @Query private var variants: [ProductVariant]

    var body: some View {
        if let variant = variants.first {
            PurchaseUnitFormView(variant: variant) { unit in
                print("Created: \(unit.displayName)")
            }
        } else {
            Text("No variants found")
        }
    }
}
