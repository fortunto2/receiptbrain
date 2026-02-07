import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query(sort: \Receipt.date, order: .reverse) private var receipts: [Receipt]
    @State private var selectedMonth = Date.now

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    totalCard
                    categoryChart
                    weeklyTrendChart
                    topCategories
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }

    // MARK: - Total Card

    private var totalCard: some View {
        let monthReceipts = receiptsForMonth(selectedMonth)
        let total = monthReceipts.reduce(Decimal(0)) { $0 + $1.totalAmount }

        return VStack(spacing: 8) {
            Text("Monthly Spending")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(total, format: .currency(code: "USD"))
                .font(.system(size: 36, weight: .bold))
            Text("\(monthReceipts.count) receipts")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Category Pie Chart

    private var categoryChart: some View {
        let data = categoryBreakdown()

        return VStack(alignment: .leading) {
            Text("By Category")
                .font(.headline)

            if data.isEmpty {
                ContentUnavailableView("No receipts", systemImage: "chart.pie")
            } else {
                Chart(data, id: \.category) { item in
                    SectorMark(
                        angle: .value("Amount", item.total as NSDecimalNumber),
                        innerRadius: .ratio(0.5)
                    )
                    .foregroundStyle(by: .value("Category", item.category.displayName))
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Weekly Trend

    private var weeklyTrendChart: some View {
        let data = weeklyBreakdown()

        return VStack(alignment: .leading) {
            Text("Weekly Trend")
                .font(.headline)

            if data.isEmpty {
                ContentUnavailableView("No data", systemImage: "chart.bar")
            } else {
                Chart(data, id: \.weekStart) { item in
                    BarMark(
                        x: .value("Week", item.weekStart, unit: .weekOfYear),
                        y: .value("Amount", item.total as NSDecimalNumber)
                    )
                    .foregroundStyle(.blue.gradient)
                }
                .frame(height: 150)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Top Categories

    private var topCategories: some View {
        let data = categoryBreakdown().prefix(5)

        return VStack(alignment: .leading) {
            Text("Top Categories")
                .font(.headline)

            ForEach(Array(data), id: \.category) { item in
                HStack {
                    Image(systemName: item.category.icon)
                        .frame(width: 24)
                    Text(item.category.displayName)
                    Spacer()
                    Text(item.total, format: .currency(code: "USD"))
                        .fontWeight(.medium)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Data Helpers

    private func receiptsForMonth(_ date: Date) -> [Receipt] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return receipts.filter {
            let rc = calendar.dateComponents([.year, .month], from: $0.date)
            return rc.year == components.year && rc.month == components.month
        }
    }

    private func categoryBreakdown() -> [(category: ExpenseCategory, total: Decimal)] {
        let monthReceipts = receiptsForMonth(selectedMonth)
        var totals: [ExpenseCategory: Decimal] = [:]
        for receipt in monthReceipts {
            totals[receipt.category, default: 0] += receipt.totalAmount
        }
        return totals.map { (category: $0.key, total: $0.value) }
            .sorted { $0.total > $1.total }
    }

    private func weeklyBreakdown() -> [(weekStart: Date, total: Decimal)] {
        let calendar = Calendar.current
        let monthReceipts = receiptsForMonth(selectedMonth)
        var weeks: [Date: Decimal] = [:]
        for receipt in monthReceipts {
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: receipt.date)?.start ?? receipt.date
            weeks[weekStart, default: 0] += receipt.totalAmount
        }
        return weeks.map { (weekStart: $0.key, total: $0.value) }
            .sorted { $0.weekStart < $1.weekStart }
    }
}
