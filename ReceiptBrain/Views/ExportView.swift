import SwiftUI
import SwiftData

struct ExportView: View {
    @Query(sort: \Receipt.date, order: .reverse) private var allReceipts: [Receipt]
    @State private var selectedMonth = Date.now
    @State private var isExporting = false
    @State private var exportedPDF: Data?
    @State private var showShareSheet = false

    private let exportService = PDFExportService()

    private var monthReceipts: [Receipt] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedMonth)
        return allReceipts.filter {
            let rc = calendar.dateComponents([.year, .month], from: $0.date)
            return rc.year == components.year && rc.month == components.month
        }
    }

    private var availableMonths: [Date] {
        let calendar = Calendar.current
        var months: Set<DateComponents> = []
        for receipt in allReceipts {
            let comp = calendar.dateComponents([.year, .month], from: receipt.date)
            months.insert(comp)
        }
        return months.compactMap { calendar.date(from: $0) }
            .sorted(by: >)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Month picker
                if !availableMonths.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(availableMonths, id: \.self) { month in
                                MonthChip(
                                    month: month,
                                    isSelected: Calendar.current.isDate(month, equalTo: selectedMonth, toGranularity: .month)
                                ) {
                                    selectedMonth = month
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Preview card
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)

                    Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                        .font(.title2.bold())

                    let total = monthReceipts.reduce(Decimal(0)) { $0 + $1.totalAmount }
                    let currency = monthReceipts.first?.currency ?? "USD"
                    Text(total.formatted(.currency(code: currency)))
                        .font(.title.bold())

                    Text("\(monthReceipts.count) receipt\(monthReceipts.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                // Category summary
                let breakdown = categoryBreakdown()
                if !breakdown.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Categories")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(breakdown, id: \.0) { category, amount in
                            HStack {
                                Image(systemName: category.icon)
                                    .frame(width: 24)
                                    .foregroundStyle(.blue)
                                Text(category.displayName)
                                Spacer()
                                Text(amount.formatted(.currency(code: monthReceipts.first?.currency ?? "USD")))
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                    }
                }

                Spacer()

                // Export button
                Button {
                    generateAndShare()
                } label: {
                    Label("Export PDF Report", systemImage: "arrow.down.doc.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(monthReceipts.isEmpty ? .gray : .blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(monthReceipts.isEmpty)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Export")
            .sheet(isPresented: $showShareSheet) {
                if let pdfData = exportedPDF {
                    PDFShareView(pdfData: pdfData, month: selectedMonth)
                }
            }
        }
    }

    private func generateAndShare() {
        let monthStr = selectedMonth.formatted(.dateTime.month(.wide).year())
        let title = "ReceiptBrain — \(monthStr)"
        exportedPDF = exportService.generateReport(
            receipts: monthReceipts,
            title: title,
            month: selectedMonth
        )
        showShareSheet = true
    }

    private func categoryBreakdown() -> [(ExpenseCategory, Decimal)] {
        var totals: [ExpenseCategory: Decimal] = [:]
        for receipt in monthReceipts {
            totals[receipt.category, default: 0] += receipt.totalAmount
        }
        return totals.sorted { $0.value > $1.value }
            .map { ($0.key, $0.value) }
    }
}

// MARK: - Month Chip

private struct MonthChip: View {
    let month: Date
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(month.formatted(.dateTime.month(.abbreviated).year(.twoDigits)))
                .font(.caption.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.secondary.opacity(0.15))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - PDF Share View

struct PDFShareView: UIViewControllerRepresentable {
    let pdfData: Data
    let month: Date

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let monthStr = month.formatted(.dateTime.month(.abbreviated).year())
        let fileName = "ReceiptBrain-\(monthStr).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? pdfData.write(to: tempURL)

        return UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
