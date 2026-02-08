import SwiftUI

struct ReceiptDetailView: View {
    let receipt: Receipt
    @State private var showOCRText = false
    @State private var imageScale: CGFloat = 1.0
    @State private var showShareSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Receipt photo
                if let imageData = receipt.imageData,
                   let uiImage = UIImage(data: imageData)
                {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(imageScale)
                        .gesture(
                            MagnifyGesture()
                                .onChanged { value in
                                    imageScale = value.magnification
                                }
                                .onEnded { _ in
                                    withAnimation { imageScale = 1.0 }
                                }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.quaternary)
                        .frame(height: 200)
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "receipt")
                                    .font(.largeTitle)
                                Text("No photo")
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                }

                // Details card
                VStack(spacing: 0) {
                    detailRow(icon: "storefront.fill", label: "Merchant", value: receipt.merchantName)
                    Divider().padding(.leading, 48)
                    detailRow(
                        icon: receipt.category.icon,
                        label: "Category",
                        value: receipt.category.displayName
                    )
                    Divider().padding(.leading, 48)
                    detailRow(
                        icon: "banknote.fill",
                        label: "Amount",
                        value: receipt.totalAmount.formatted(.currency(code: receipt.currency))
                    )
                    Divider().padding(.leading, 48)
                    detailRow(
                        icon: "calendar",
                        label: "Date",
                        value: receipt.date.formatted(.dateTime.month(.abbreviated).day().year())
                    )
                    Divider().padding(.leading, 48)
                    detailRow(
                        icon: "creditcard.fill",
                        label: "Payment",
                        value: receipt.paymentMethod.displayName
                    )
                }
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                // OCR text (collapsible)
                if !receipt.rawOCRText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            withAnimation { showOCRText.toggle() }
                        } label: {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("Raw OCR Text")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: showOCRText ? "chevron.up" : "chevron.down")
                            }
                            .foregroundStyle(.primary)
                        }

                        if showOCRText {
                            Text(receipt.rawOCRText)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Receipt")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                showShareSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(items: receipt.shareItems)
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(.blue)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

// MARK: - UIActivityViewController wrapper

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
