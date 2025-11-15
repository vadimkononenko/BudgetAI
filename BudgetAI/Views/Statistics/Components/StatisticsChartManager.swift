//
//  StatisticsChartManager.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 14.11.2025.
//

import UIKit
import SnapKit

/// Manages chart view controllers for the statistics screen
/// Handles creation, configuration, and updates of pie chart, line chart, and bar chart
final class StatisticsChartManager {

    // MARK: - Properties

    /// Pie chart view controller for category expense distribution
    private(set) var pieChartViewController: ExpensePieChartViewController?

    /// Line chart view controller for expense trends over time
    private(set) var lineChartViewController: ExpenseTrendLineChartViewController?

    /// Bar chart view controller for monthly expense comparisons
    private(set) var barChartViewController: MonthComparisonBarChartViewController?

    /// Parent view controller that owns these chart controllers
    private weak var parentViewController: UIViewController?

    /// Container view where chart views will be added
    private weak var containerView: UIView?

    // MARK: - Initialization

    /// Initializes the chart manager
    /// - Parameters:
    ///   - parentViewController: The parent view controller that will host the charts
    ///   - containerView: The view that will contain the chart views
    init(parentViewController: UIViewController, containerView: UIView) {
        self.parentViewController = parentViewController
        self.containerView = containerView
    }

    // MARK: - Setup

    /// Sets up all chart view controllers with initial data and constraints
    /// - Parameters:
    ///   - categoryStats: Initial category statistics for pie chart
    ///   - dailyExpenses: Initial daily expense data for line chart
    ///   - monthlyData: Initial monthly comparison data for bar chart
    ///   - selectedPeriod: Currently selected time period
    ///   - topAnchor: The view to anchor the first chart below
    ///   - onCategoryTap: Callback when a category is tapped in the pie chart
    /// - Returns: The last chart view for further constraint setup
    @discardableResult
    func setupCharts(
        categoryStats: [CategoryStatDisplayModel],
        dailyExpenses: [ChartDataFormatter.DailyExpense],
        monthlyData: [ChartDataFormatter.MonthlyData],
        selectedPeriod: DateRangeCalculator.PeriodFilter,
        topAnchor: UIView,
        onCategoryTap: @escaping (Category) -> Void
    ) -> UIView? {
        guard let parent = parentViewController,
              let container = containerView else {
            return nil
        }

        // Setup Pie Chart
        let pieChartVC = ExpensePieChartViewController(
            categoryStats: categoryStats,
            onCategoryTap: onCategoryTap
        )
        pieChartViewController = pieChartVC
        parent.addChild(pieChartVC)
        container.addSubview(pieChartVC.view)
        pieChartVC.view.translatesAutoresizingMaskIntoConstraints = false
        pieChartVC.didMove(toParent: parent)

        // Setup Line Chart
        let lineChartVC = ExpenseTrendLineChartViewController(
            dailyExpenses: dailyExpenses,
            selectedPeriod: selectedPeriod
        )
        lineChartViewController = lineChartVC
        parent.addChild(lineChartVC)
        container.addSubview(lineChartVC.view)
        lineChartVC.view.translatesAutoresizingMaskIntoConstraints = false
        lineChartVC.didMove(toParent: parent)

        // Setup Bar Chart
        let barChartVC = MonthComparisonBarChartViewController(
            monthlyData: monthlyData
        )
        barChartViewController = barChartVC
        parent.addChild(barChartVC)
        container.addSubview(barChartVC.view)
        barChartVC.view.translatesAutoresizingMaskIntoConstraints = false
        barChartVC.didMove(toParent: parent)

        // Setup Constraints
        setupConstraints(topAnchor: topAnchor)

        return barChartVC.view
    }

    /// Sets up layout constraints for all chart views
    /// - Parameter topAnchor: The view to anchor the first chart below
    private func setupConstraints(topAnchor: UIView) {
        guard let pieChartView = pieChartViewController?.view,
              let lineChartView = lineChartViewController?.view,
              let barChartView = barChartViewController?.view,
              let container = containerView else {
            return
        }

        // Pie Chart Constraints
        pieChartView.snp.makeConstraints { make in
            make.top.equalTo(topAnchor.snp.bottom).offset(20)
            make.leading.equalTo(container.snp.leading)
            make.trailing.equalTo(container.snp.trailing)
        }

        // Line Chart Constraints
        lineChartView.snp.makeConstraints { make in
            make.top.equalTo(pieChartView.snp.bottom).offset(20)
            make.leading.equalTo(container.snp.leading)
            make.trailing.equalTo(container.snp.trailing)
        }

        // Bar Chart Constraints
        barChartView.snp.makeConstraints { make in
            make.top.equalTo(lineChartView.snp.bottom).offset(20)
            make.leading.equalTo(container.snp.leading)
            make.trailing.equalTo(container.snp.trailing)
        }
    }

    // MARK: - Updates

    /// Updates all charts with new data
    /// - Parameters:
    ///   - categoryStats: Updated category statistics
    ///   - dailyExpenses: Updated daily expense data
    ///   - monthlyData: Updated monthly comparison data
    ///   - selectedPeriod: Updated selected period
    func updateCharts(
        categoryStats: [CategoryStatDisplayModel],
        dailyExpenses: [ChartDataFormatter.DailyExpense],
        monthlyData: [ChartDataFormatter.MonthlyData],
        selectedPeriod: DateRangeCalculator.PeriodFilter
    ) {
        pieChartViewController?.updateData(categoryStats)
        lineChartViewController?.updateData(dailyExpenses, selectedPeriod: selectedPeriod)
        barChartViewController?.updateData(monthlyData)
    }

    /// Updates visibility of all chart views
    /// - Parameter isVisible: Whether charts should be visible
    func setChartsVisibility(_ isVisible: Bool) {
        pieChartViewController?.view.isHidden = !isVisible
        lineChartViewController?.view.isHidden = !isVisible
        barChartViewController?.view.isHidden = !isVisible
    }

    // MARK: - Getters

    /// Returns the bottom-most chart view for layout purposes
    /// - Returns: The bar chart view if available, nil otherwise
    func getBottomChartView() -> UIView? {
        return barChartViewController?.view
    }
}
