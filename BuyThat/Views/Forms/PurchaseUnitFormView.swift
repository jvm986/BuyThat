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
    @Query(sort: \ContainerType.name) private var containerTypes: [ContainerType]

    let variant: ProductVariant
    let purchaseUnit: PurchaseUnit?
    let onSave: (PurchaseUnit) -> Void

    @State private var conversionText: String = ""
    @State private var selectedUnit: MeasurementUnit
    @State private var isInverted: Bool = false
    @State private var selectedContainerType: ContainerType?

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
            _selectedContainerType = State(initialValue: unit.containerType)
        } else {
            _selectedUnit = State(initialValue: .units)
            _isInverted = State(initialValue: true)
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

    private var effectiveLabel: String {
        selectedContainerType?.name ?? selectedUnit.singularSymbol
    }

    private var effectivePluralLabel: String {
        selectedContainerType?.pluralName ?? selectedUnit.symbol
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Container Type", selection: $selectedContainerType) {
                        Text("None").tag(ContainerType?.none)
                        ForEach(containerTypes) { ct in
                            Text(ct.name.capitalized).tag(ContainerType?.some(ct))
                        }
                    }
                } header: {
                    Text("Container (Optional)")
                } footer: {
                    Text("Give this purchase unit a name like \"bottle\" or \"bag\". Leave as None to use the measurement unit symbol.")
                }

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
                        ForEach(MeasurementUnit.allCases, id: \.self) { unit in
                            Text(unit.displayLabel).tag(unit)
                        }
                    }
                } header: {
                    Text("Measurement")
                } footer: {
                    if isInverted {
                        Text("How many \(variant.baseUnit.symbol) equals 1 \(effectiveLabel)?")
                    } else {
                        Text("How many \(effectivePluralLabel) equals 1 \(variant.baseUnit.symbol)?")
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
            .onChange(of: selectedUnit) { oldValue, newValue in
                autoFillConversion(from: oldValue, to: newValue)
            }
        }
    }

    private func autoFillConversion(from oldUnit: MeasurementUnit, to newUnit: MeasurementUnit) {
        // Only auto-fill if the conversion text is empty or was previously auto-filled
        guard conversionText.isEmpty || wasAutoFilled(oldUnit) else { return }

        if let factor = variant.baseUnit.conversionFactor(to: newUnit) {
            let value = isInverted ? (1.0 / factor) : factor
            conversionText = value.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(value))
                : String(format: "%.5g", value)
        }
    }

    private func wasAutoFilled(_ unit: MeasurementUnit) -> Bool {
        // Check if the current text matches what auto-fill would have set for the old unit
        guard let factor = variant.baseUnit.conversionFactor(to: unit) else { return false }
        let value = isInverted ? (1.0 / factor) : factor
        let expected = value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.5g", value)
        return conversionText == expected
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
            purchaseUnitSymbol: effectiveLabel,
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
            existingUnit.containerType = selectedContainerType
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
            newUnit.containerType = selectedContainerType
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
