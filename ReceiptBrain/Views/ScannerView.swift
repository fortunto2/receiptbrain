import SwiftUI
import PhotosUI

struct ScannerView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel = ScannerViewModel()
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if viewModel.isProcessing {
                    ProgressView("Scanning receipt...")
                        .frame(maxHeight: .infinity)
                } else if viewModel.parsedReceipt != nil {
                    reviewForm
                } else {
                    captureButtons
                }
            }
            .padding()
            .navigationTitle("Scan Receipt")
            .sheet(isPresented: $showCamera) {
                CameraView { image in
                    showCamera = false
                    Task { await viewModel.processImage(image) }
                }
            }
            .onChange(of: viewModel.selectedPhoto) { _, newValue in
                guard let item = newValue else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data)
                    {
                        await viewModel.processImage(image)
                    }
                }
            }
        }
    }

    // MARK: - Capture Buttons

    private var captureButtons: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "receipt")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)

            Text("Scan a receipt to track your spending")
                .font(.headline)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                showCamera = true
            } label: {
                Label("Take Photo", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            PhotosPicker(
                selection: $viewModel.selectedPhoto,
                matching: .images
            ) {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    // MARK: - Review Form

    private var reviewForm: some View {
        Form {
            if let image = viewModel.capturedImage {
                Section {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            Section("Receipt Details") {
                TextField("Merchant", text: $viewModel.merchantName)
                TextField("Amount", text: $viewModel.totalAmount)
                    .keyboardType(.decimalPad)
                DatePicker("Date", selection: $viewModel.receiptDate, displayedComponents: .date)
                Picker("Category", selection: $viewModel.selectedCategory) {
                    ForEach(ExpenseCategory.allCases) { cat in
                        Label(cat.displayName, systemImage: cat.icon).tag(cat)
                    }
                }
                Picker("Payment", selection: $viewModel.selectedPaymentMethod) {
                    ForEach(PaymentMethod.allCases) { method in
                        Text(method.displayName).tag(method)
                    }
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }

            Section {
                Button("Save Receipt") {
                    viewModel.saveReceipt(context: context)
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)

                Button("Cancel", role: .cancel) {
                    viewModel.reset()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
