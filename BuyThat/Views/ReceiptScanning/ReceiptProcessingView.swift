//
//  ReceiptProcessingView.swift
//  BuyThat
//

import SwiftUI

struct ReceiptProcessingView: View {
    let image: UIImage
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 4)

            ProgressView()
                .scaleEffect(1.2)

            Text("Analyzing receipt...")
                .font(.headline)
                .foregroundStyle(.secondary)

            Button("Cancel", role: .cancel) {
                onCancel()
            }
        }
        .padding()
    }
}
