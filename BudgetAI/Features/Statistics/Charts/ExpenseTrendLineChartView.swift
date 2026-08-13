//
//  ExpenseTrendLineChartView.swift
//  BudgetAI
//
//  Created by Vadim Kononenko
//

import UIKit
import SwiftUI
import Charts

/// Data model representing daily expense data
typealias DailyExpense = ChartDataFormatter.DailyExpense

/// SwiftUI view displaying a line chart showing expense trends over time
struct ExpenseTrendLineChartView: View {
    // MARK: - Properties

    let dailyExpenses: [DailyExpense]
    let selectedPeriod: DateRangeCalculator.PeriodFilter

    @State private var selectedDate: Date?

    // MARK: - Body

    var body: some View {
        ChartStyleConfigurator.chartContainer {
            VStack(alignment: .leading, spacing: ChartStyleConfigurator.standardVerticalSpacing) {
                Text(L10n.Statistics.expenseTrend)
                    .font(ChartStyleConfigurator.titleFont)
                    .foregroundColor(Color(uiColor: .label))
                    .padding(.horizontal, ChartStyleConfigurator.standardHorizontalPadding)

                if dailyExpenses.isEmpty {
                    ChartStyleConfigurator.emptyStateView(
                        iconName: "chart.line.uptrend.xyaxis",
                        message: L10n.Statistics.noData,
                        height: ChartStyleConfigurator.trendChartHeight
                    )
                } else {
                    chartView
                    selectedExpenseInfoView
                }
            }
        }
    }

    // MARK: - Chart View

    /// Main line chart with area fill displaying expense trends
    private var chartView: some View {
        Chart {
            ForEach(dailyExpenses) { expense in
                LineMark(
                    x: .value("Date", expense.date, unit: ChartStyleConfigurator.timeUnit(for: selectedPeriod)),
                    y: .value("Amount", expense.amount)
                )
                .foregroundStyle(ChartStyleConfigurator.expenseColor.gradient)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Date", expense.date, unit: ChartStyleConfigurator.timeUnit(for: selectedPeriod)),
                    y: .value("Amount", expense.amount)
                )
                .foregroundStyle(ChartStyleConfigurator.areaGradient(baseColor: ChartStyleConfigurator.expenseColor))
                .interpolationMethod(.catmullRom)
            }

            if let selectedDate = selectedDate {
                RuleMark(x: .value("Selected Date", selectedDate))
                    .foregroundStyle(ChartStyleConfigurator.selectionColor)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
            }
        }
        .chartXSelection(value: $selectedDate)
        .chartYAxis {
            ChartStyleConfigurator.yAxisMarks()
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisValueLabel(
                    format: ChartStyleConfigurator.dateFormatStyle(for: selectedPeriod),
                    centered: true
                )
                .font(ChartStyleConfigurator.axisLabelFont)
            }
        }
        .frame(height: ChartStyleConfigurator.trendChartHeight)
        .padding(.horizontal, ChartStyleConfigurator.standardHorizontalPadding)
    }

    // MARK: - Selected Expense Info View

    /// Displays information for the selected date point
    @ViewBuilder
    private var selectedExpenseInfoView: some View {
        if let selectedDate = selectedDate,
           let selectedExpense = dailyExpenses.first(where: {
               Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
           }) {
            ChartStyleConfigurator.infoCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ChartStyleConfigurator.formatDate(selectedExpense.date, for: selectedPeriod))
                            .font(ChartStyleConfigurator.smallDataLabelFont)
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                        Text(CurrencyFormatter.shared.format(selectedExpense.amount))
                            .font(ChartStyleConfigurator.largeValueFont)
                            .foregroundColor(Color(uiColor: .label))
                    }
                    Spacer()
                }
            }
        }
    }
}

// MARK: - UIKit Wrapper

/// UIKit wrapper for ExpenseTrendLineChartView to enable usage in UIKit-based views
final class ExpenseTrendLineChartViewController: UIViewController {

    // MARK: - Properties

    private var dailyExpenses: [DailyExpense]
    private var selectedPeriod: StatisticsViewModel.PeriodFilter

    // MARK: - Initialization

    /// Initializes the view controller with expense data and period filter
    /// - Parameters:
    ///   - dailyExpenses: Array of daily expense data to display
    ///   - selectedPeriod: The time period filter for the chart
    init(dailyExpenses: [DailyExpense], selectedPeriod: StatisticsViewModel.PeriodFilter) {
        self.dailyExpenses = dailyExpenses
        self.selectedPeriod = selectedPeriod
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

    /// Updates the chart with new expense data and period filter
    /// - Parameters:
    ///   - dailyExpenses: New array of daily expense data
    ///   - selectedPeriod: New time period filter
    func updateData(_ dailyExpenses: [DailyExpense], selectedPeriod: StatisticsViewModel.PeriodFilter) {
        self.dailyExpenses = dailyExpenses
        self.selectedPeriod = selectedPeriod
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

        let chartView = ExpenseTrendLineChartView(
            dailyExpenses: dailyExpenses,
            selectedPeriod: selectedPeriod
        )
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
