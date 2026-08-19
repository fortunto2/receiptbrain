import SwiftUI
import SwiftData

@main
struct ReceiptBrainApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([Receipt.self])
        let config = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .automatic
        )
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        #if DEBUG
        // Store screenshots need a populated app, and the simulator has no
        // camera. Compiled out of any release build; only runs when launched
        // with -seedDemoReceipts, so normal debug runs are unaffected.
        if ProcessInfo.processInfo.arguments.contains("-seedDemoReceipts") {
            Self.seedDemoReceipts(into: container)
        }
        #endif
    }

    #if DEBUG
    private static func seedDemoReceipts(into container: ModelContainer) {
        let context = ModelContext(container)
        let existing = (try? context.fetch(FetchDescriptor<Receipt>())) ?? []
        guard existing.isEmpty else { return }

        let day = Calendar.current.startOfDay(for: .now)
        func date(_ ago: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: -ago, to: day) ?? day
        }

        let demo: [(String, Decimal, ExpenseCategory, PaymentMethod, Int)] = [
            ("Whole Foods Market", 42.15, .groceries, .creditCard, 1),
            ("Starbucks", 9.20, .dining, .creditCard, 0),
            ("Shell", 40.80, .transport, .creditCard, 2),
            ("Trader Joe's", 63.40, .groceries, .debitCard, 4),
            ("Uber", 18.75, .transport, .creditCard, 5),
            ("Chipotle", 14.60, .dining, .cash, 6),
            ("CVS Pharmacy", 27.90, .health, .creditCard, 8),
            ("Apple Store", 129.00, .shopping, .creditCard, 11),
        ]

        for (merchant, amount, category, payment, ago) in demo {
            context.insert(Receipt(
                merchantName: merchant,
                totalAmount: amount,
                currency: "USD",
                date: date(ago),
                category: category,
                paymentMethod: payment,
                imageData: demoReceiptImage(merchant: merchant, amount: amount,
                                            date: date(ago)).jpegData(compressionQuality: 0.85)
            ))
        }
        try? context.save()
    }

    /// Draws a plausible receipt so the detail screen shows a photo rather than
    /// a placeholder. Debug only — the real app stores what the camera captured.
    private static func demoReceiptImage(merchant: String, amount: Decimal, date: Date) -> UIImage {
        let size = CGSize(width: 640, height: 460)
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy  HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        return UIGraphicsImageRenderer(size: size).image { ctx in
            UIColor(white: 0.965, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            func draw(_ text: String, _ y: CGFloat, size fontSize: CGFloat, bold: Bool = false) {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedSystemFont(ofSize: fontSize,
                                                       weight: bold ? .bold : .regular),
                    .foregroundColor: UIColor(white: 0.12, alpha: 1),
                ]
                (text as NSString).draw(at: CGPoint(x: 36, y: y), withAttributes: attrs)
            }

            draw(merchant.uppercased(), 34, size: 30, bold: true)
            draw("Austin, TX", 78, size: 20)
            draw(String(repeating: "-", count: 34), 130, size: 20)
            draw("SUBTOTAL", 180, size: 22)
            draw("TAX", 220, size: 22)
            draw("TOTAL", 280, size: 26, bold: true)
            draw(formatter.string(from: date), 350, size: 20)

            let total = NSDecimalNumber(decimal: amount).doubleValue
            func right(_ text: String, _ y: CGFloat, size fontSize: CGFloat, bold: Bool = false) {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedSystemFont(ofSize: fontSize,
                                                       weight: bold ? .bold : .regular),
                    .foregroundColor: UIColor(white: 0.12, alpha: 1),
                ]
                let str = text as NSString
                let width = str.size(withAttributes: attrs).width
                str.draw(at: CGPoint(x: size.width - 36 - width, y: y), withAttributes: attrs)
            }
            right(String(format: "%.2f", total * 0.92), 180, size: 22)
            right(String(format: "%.2f", total * 0.08), 220, size: 22)
            right(String(format: "%.2f", total), 280, size: 26, bold: true)
        }
    }
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
