//
//  ReceiptScanningCoordinator.swift
//  BuyThat
//

import PhotosUI
import SwiftUI

struct ReceiptScanningCoordinator: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var flowState: FlowState = .selectingImage
    @State private var selectedImage: UIImage?
    @State private var parsedReceipt: ParsedReceipt?
    @State private var matchedItems: [MatchedReceiptItem] = []
    @State private var selectedStore: Store?
    @State private var errorMessage: String?
    @State private var scanTask: Task<Void, Never>?
    @State private var saveResult: ReceiptSaveResult?

    // Image source
    @State private var showingImageSourceDialog = false
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var photoPickerItem: PhotosPickerItem?

    enum FlowState {
        case apiKeySetup
        case selectingImage
        case processing
        case confirmingStore
        case reviewing
        case saved
        case error
    }

    var body: some View {
        NavigationStack {
            Group {
                switch flowState {
                case .apiKeySetup:
                    APIKeySetupView {
                        flowState = .selectingImage
                    }

                case .selectingImage:
                    selectingImageView

                case .processing:
                    if let image = selectedImage {
                        ReceiptProcessingView(image: image) {
                            cancelProcessing()
                        }
                    }

                case .confirmingStore:
                    StoreConfirmationView(
                        detectedStoreName: parsedReceipt?.storeName,
                        matchedStoreName: parsedReceipt?.matchedStoreName
                    ) { store in
                        selectedStore = store
                        performMatching(store: store)
                    }

                case .reviewing:
                    ReceiptReviewView(
                        store: selectedStore!,
                        receiptDate: parsedReceipt?.receiptDate,
                        items: $matchedItems
                    ) {
                        saveResults()
                    }

                case .saved:
                    if let trip = saveResult?.shoppingTrip {
                        ShoppingTripDetailView(trip: trip)
                    }

                case .error:
                    errorView
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(flowState == .saved ? "Done" : "Cancel") {
                        cancelProcessing()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if !APIKeyManager.hasAPIKey() {
                flowState = .apiKeySetup
            }
        }
        .confirmationDialog("Add Receipt Image", isPresented: $showingImageSourceDialog, titleVisibility: .visible) {
            Button("Take Photo") {
                showingCamera = true
            }
            Button("Choose from Library") {
                showingPhotoPicker = true
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView { image in
                showingCamera = false
                if let image {
                    selectedImage = image
                    startProcessing()
                } else {
                    dismiss()
                }
            }
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $photoPickerItem, matching: .images)
        .onChange(of: photoPickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                    startProcessing()
                }
            }
        }
    }

    // MARK: - Selecting Image View

    private var selectingImageView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Scan a Receipt")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Take a photo of your receipt or choose one from your library to automatically update prices.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Select Image") {
                showingImageSourceDialog = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Error View

    private var errorView: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.orange)

            Text("Something went wrong")
                .font(.title2)
                .fontWeight(.semibold)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            HStack(spacing: 16) {
                Button("Try Again") {
                    self.errorMessage = nil
                    flowState = .selectingImage
                    showingImageSourceDialog = true
                }
                .buttonStyle(.borderedProminent)

                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .padding()
    }

    // MARK: - Actions

    private func startProcessing() {
        flowState = .processing
        scanTask = Task {
            do {
                let receipt = try await ReceiptScannerService.scanReceipt(
                    image: selectedImage!,
                    context: modelContext
                )
                guard !Task.isCancelled else { return }
                parsedReceipt = receipt
                flowState = .confirmingStore
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
                flowState = .error
            }
        }
    }

    private func cancelProcessing() {
        scanTask?.cancel()
        scanTask = nil
    }

    private func performMatching(store: Store) {
        guard let receipt = parsedReceipt else { return }
        matchedItems = ReceiptMatchingService.matchItems(
            receipt.items,
            store: store,
            context: modelContext
        )
        flowState = .reviewing
    }

    private func saveResults() {
        guard let store = selectedStore else { return }
        saveResult = ReceiptMatchingService.saveMatchedItems(
            matchedItems,
            store: store,
            receiptDate: parsedReceipt?.receiptDate,
            context: modelContext
        )
        flowState = .saved
    }
}

// MARK: - Camera View (UIImagePickerController wrapper)

struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCaptured: onImageCaptured)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageCaptured: (UIImage?) -> Void

        init(onImageCaptured: @escaping (UIImage?) -> Void) {
            self.onImageCaptured = onImageCaptured
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            onImageCaptured(image)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onImageCaptured(nil)
        }
    }
}
