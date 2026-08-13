//
//  MonthComparisonBarChartView.swift
//  BudgetAI
//
//  Created by Vadim Kononenko
//

import UIKit
import SwiftUI
import Charts

/// Data model representing financial data for a single month
typealias MonthlyData = ChartDataFormatter.MonthlyData

/// SwiftUI view displaying a bar chart comparing income and expenses across months
struct MonthComparisonBarChartView: View {
    // MARK: - Properties

    let monthlyData: [MonthlyData]

    @State private var selectedMonth: String?
    @State private var showIncome = true
    @State private var showExpense = true

    // MARK: - Body

    var body: some View {
        ChartStyleConfigurator.chartContainer {
            VStack(alignment: .leading, spacing: ChartStyleConfigurator.standardVerticalSpacing) {
                headerView

                if monthlyData.isEmpty {
                    ChartStyleConfigurator.emptyStateView(
                        iconName: "chart.bar.fill",
                        message: L10n.Statistics.noData,
                        height: ChartStyleConfigurator.standardChartHeight
                    )
                } else {
                    chartView
                    selectedMonthInfoView
                    statisticsView
                }
            }
        }
    }

    // MARK: - Header View

    /// Header with title and filter menu
    private var headerView: some View {
        HStack {
            Text(L10n.Statistics.monthComparison)
                .font(ChartStyleConfigurator.titleFont)
                .foregroundColor(Color(uiColor: .label))

            Spacer()

            Menu {
                Button(action: { showIncome.toggle() }) {
                    Label(L10n.Statistics.income, systemImage: showIncome ? "checkmark" : "")
                }

                Button(action: { showExpense.toggle() }) {
                    Label(L10n.Statistics.expenses, systemImage: showExpense ? "checkmark" : "")
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 20))
                    .foregroundColor(Color(uiColor: .systemBlue))
            }
        }
        .padding(.horizontal, ChartStyleConfigurator.standardHorizontalPadding)
    }

    // MARK: - Chart View

    /// Main bar chart displaying income and expenses
    private var chartView: some View {
        Chart {
            ForEach(monthlyData) { data in
                if showIncome {
                    BarMark(
                        x: .value("Month", data.month),
                        y: .value("Income", data.income)
                    )
                    .foregroundStyle(ChartStyleConfigurator.incomeColor.gradient)
                    .position(by: .value("Type", "Income"))
                }

                if showExpense {
                    BarMark(
                        x: .value("Month", data.month),
                        y: .value("Expenses", data.expense)
                    )
                    .foregroundStyle(ChartStyleConfigurator.expenseColor.gradient)
                    .position(by: .value("Type", "Expenses"))
                }
            }
        }
        .chartXSelection(value: $selectedMonth)
        .chartYAxis {
            ChartStyleConfigurator.yAxisMarks()
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let month = value.as(String.self) {
                        Text(month)
                            .font(ChartStyleConfigurator.axisLabelFont)
                            .lineLimit(1)
                    }
                }
            }
        }
        .chartLegend(position: .bottom, spacing: 8)
        .frame(height: ChartStyleConfigurator.standardChartHeight)
        .padding(.horizontal, ChartStyleConfigurator.standardHorizontalPadding)
    }

    // MARK: - Selected Month Info View

    /// Displays detailed information for the selected month
    @ViewBuilder
    private var selectedMonthInfoView: some View {
        if let selectedMonth = selectedMonth,
           let selectedData = monthlyData.first(where: { $0.month == selectedMonth }) {
            ChartStyleConfigurator.infoCard {
                VStack(spacing: 12) {
                    Text(ChartStyleConfigurator.formatMonthYear(selectedData.date))
                        .font(ChartStyleConfigurator.dataLabelFont)
                        .foregroundColor(Color(uiColor: .secondaryLabel))

                    HStack(spacing: 24) {
                        if showIncome {
                            ChartStyleConfigurator.dataValueView(
                                label: L10n.Statistics.income,
                                value: CurrencyFormatter.shared.format(selectedData.income),
                                valueColor: ChartStyleConfigurator.incomeColor
                            )
                        }

                        if showExpense {
                            ChartStyleConfigurator.dataValueView(
                                label: L10n.Statistics.expenses,
                                value: CurrencyFormatter.shared.format(selectedData.expense),
                                valueColor: ChartStyleConfigurator.expenseColor
                            )
                        }

                        ChartStyleConfigurator.dataValueView(
                            label: L10n.Statistics.balance,
                            value: CurrencyFormatter.shared.format(selectedData.balance),
                            valueColor: selectedData.balance >= 0 ? ChartStyleConfigurator.incomeColor : ChartStyleConfigurator.expenseColor
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Statistics View

    /// Displays average income and expense statistics
    private var statisticsView: some View {
        ChartStyleConfigurator.infoCard {
            VStack(spacing: 8) {
                HStack {
                    Text(L10n.Statistics.averageIndicators)
                        .font(ChartStyleConfigurator.dataLabelFont)
                        .foregroundColor(Color(uiColor: .label))
                    Spacer()
                }

                HStack(spacing: 20) {
                    if showIncome {
                        ChartStyleConfigurator.compactDataValueView(
                            label: L10n.Statistics.averageIncome,
                            value: CurrencyFormatter.shared.format(averageIncome),
                            valueColor: ChartStyleConfigurator.incomeColor
                        )
                    }

                    if showExpense {
                        ChartStyleConfigurator.compactDataValueView(
                            label: L10n.Statistics.averageExpenses,
                            value: CurrencyFormatter.shared.format(averageExpense),
                            valueColor: ChartStyleConfigurator.expenseColor
                        )
                    }

                    Spacer()
                }
            }
        }
    }

    // MARK: - Computed Properties

    /// Calculates average income across all months
    private var averageIncome: Double {
        guard !monthlyData.isEmpty else { return 0 }
        return monthlyData.reduce(0) { $0 + $1.income } / Double(monthlyData.count)
    }

    /// Calculates average expense across all months
    private var averageExpense: Double {
        guard !monthlyData.isEmpty else { return 0 }
        return monthlyData.reduce(0) { $0 + $1.expense } / Double(monthlyData.count)
    }
}

// MARK: - UIKit Wrapper

/// UIKit wrapper for MonthComparisonBarChartView to enable usage in UIKit-based views
final class MonthComparisonBarChartViewController: UIViewController {

    // MARK: - Properties

    private var monthlyData: [MonthlyData]

    // MARK: - Initialization

    /// Initializes the view controller with monthly data
    /// - Parameter monthlyData: Array of monthly financial data to display
    init(monthlyData: [MonthlyData]) {
        self.monthlyData = monthlyData
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSwiftUIView()
    }

    // MARK: - Public Methods

    /// Updates the chart with new monthly data
    /// - Parameter monthlyData: New array of monthly financial data
    func updateData(_ monthlyData: [MonthlyData]) {
        self.monthlyData = monthlyData
        setupSwiftUIView()
    }

    // MARK: - Private Methods

    /// Sets up the SwiftUI hosting controller and embeds the chart view
    private func setupSwiftUIView() {
        // Remove previous views
        children.forEach { child in
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }

        let chartView = MonthComparisonBarChartView(monthlyData: monthlyData)
        let hostingController = UIHostingController(rootView: chartView)

        addChild(hostingController)
        view.addSubview(hostingController.view)

        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        hostingController.didMove(toParent: self)
    }
}
