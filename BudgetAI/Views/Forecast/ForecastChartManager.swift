//
//  ForecastChartManager.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 14.11.2025.
//

import UIKit

/// Manages chart-related functionality for the forecast view
/// Handles creation, configuration, and updates of forecast visualization charts
final class ForecastChartManager {

    // MARK: - Properties

    /// Data formatter providing formatted data for charts
    private let dataFormatter: ForecastDataFormatter

    /// UI builder providing chart container views
    private let uiBuilder: ForecastUIBuilder

    // MARK: - Initialization

    /// Initializes the chart manager with required dependencies
    /// - Parameters:
    ///   - dataFormatter: Formatter for preparing chart data
    ///   - uiBuilder: Builder for UI components
    init(dataFormatter: ForecastDataFormatter, uiBuilder: ForecastUIBuilder) {
        self.dataFormatter = dataFormatter
        self.uiBuilder = uiBuilder
    }

    // MARK: - Public Methods

    /// Updates all chart views with current forecast data
    /// This method should be called whenever the underlying data changes
    func updateCharts() {
        updateTotalCard()
        updateDataProgressView()
        updateEmptyState()
    }

    /// Configures the data progress view visibility and content
    /// Shows progress when there is some data but less than optimal amount
    func configureDataProgressView() {
        let shouldShowProgress = dataFormatter.shouldShowDataProgress()

        if shouldShowProgress {
            uiBuilder.dataProgressView.configure(
                currentMonths: dataFormatter.getMonthsOfData(),
                requiredMonths: 3,
                showWarning: dataFormatter.isBasicForecast()
            )
        }

        if uiBuilder.dataProgressView.isHidden != !shouldShowProgress {
            uiBuilder.dataProgressView.isHidden = !shouldShowProgress
            uiBuilder.updateTotalCardPosition()
        }
    }

    /// Shows or hides the empty state view based on data availability
    /// - Parameter tableView: The table view to update visibility for
    func toggleEmptyState(for tableView: UITableView) {
        if dataFormatter.isEmpty() {
            tableView.backgroundView?.isHidden = false
        } else {
            tableView.backgroundView?.isHidden = true
        }
    }

    /// Updates the header view height to accommodate its content
    /// Should be called after layout changes
    /// - Parameter tableView: The table view containing the header
    func updateHeaderHeight(for tableView: UITableView) {
        uiBuilder.updateHeaderViewHeight(for: tableView)
    }

    /// Gets the formatted total amount for display
    /// - Returns: Currency-formatted total forecast amount
    func getFormattedTotal() -> String {
        return dataFormatter.getFormattedTotalAmount()
    }

    /// Gets the month label text
    /// - Returns: Formatted month name
    func getMonthText() -> String {
        return dataFormatter.getFormattedMonthName()
    }

    /// Gets the subtitle text
    /// - Returns: Appropriate subtitle based on forecast status
    func getSubtitleText() -> String {
        return dataFormatter.getSubtitleText()
    }

    /// Gets the subtitle color
    /// - Returns: Appropriate color based on forecast status
    func getSubtitleColor() -> UIColor {
        return dataFormatter.getSubtitleColor()
    }

    // MARK: - Private Methods

    /// Updates the total card with current forecast total
    private func updateTotalCard() {
        let formattedTotal = dataFormatter.getFormattedTotalAmount()
        uiBuilder.updateTotalAmount(formattedTotal)
    }

    /// Updates the data progress view with current data collection status
    private func updateDataProgressView() {
        let shouldShowProgress = dataFormatter.shouldShowDataProgress()

        if shouldShowProgress {
            let currentMonths = dataFormatter.getMonthsOfData()
            let isBasicForecast = dataFormatter.isBasicForecast()

            uiBuilder.dataProgressView.configure(
                currentMonths: currentMonths,
                requiredMonths: 3,
                showWarning: isBasicForecast
            )
        }
    }

    /// Updates the empty state view with appropriate message
    private func updateEmptyState() {
        if dataFormatter.isEmpty() {
            let message = dataFormatter.getEmptyStateMessage()
            uiBuilder.emptyStateLabel.text = message
        }
    }
}

// MARK: - Chart Data Model

/// Represents data for a single chart point
struct ChartDataPoint {
    /// The category name for this data point
    let categoryName: String

    /// The forecasted value
    let value: Double

    /// The percentage of total forecast
    let percentage: Double

    /// Color for visualization
    let color: UIColor
}

// MARK: - Chart Configuration

/// Configuration options for forecast charts
struct ForecastChartConfiguration {
    /// Chart background color
    let backgroundColor: UIColor

    /// Chart border color
    let borderColor: UIColor

    /// Chart border width
    let borderWidth: CGFloat

    /// Chart corner radius
    let cornerRadius: CGFloat

    /// Whether to show legend
    let showLegend: Bool

    /// Whether to animate on appearance
    let animate: Bool

    /// Default configuration
    static let `default` = ForecastChartConfiguration(
        backgroundColor: .systemBackground,
        borderColor: .separator,
        borderWidth: 1.0,
        cornerRadius: 12.0,
        showLegend: true,
        animate: true
    )
}

// MARK: - Chart View Protocol

/// Protocol defining requirements for chart views
protocol ForecastChartView {
    /// Updates the chart with new data points
    /// - Parameter dataPoints: Array of chart data points to display
    func update(with dataPoints: [ChartDataPoint])

    /// Configures the chart appearance
    /// - Parameter configuration: Chart configuration settings
    func configure(with configuration: ForecastChartConfiguration)

    /// Clears all chart data and resets to empty state
    func clear()
}

// MARK: - Chart Type Enumeration

/// Enumeration of available chart types for forecast visualization
enum ForecastChartType {
    /// Bar chart showing category comparisons
    case bar

    /// Pie chart showing category distribution
    case pie

    /// Line chart showing trends over time
    case line
}

// MARK: - Chart Factory

/// Factory for creating different types of forecast charts
final class ForecastChartFactory {
    /// Creates a chart view of the specified type
    /// - Parameter type: The type of chart to create
    /// - Returns: A view conforming to ForecastChartView protocol
    static func createChart(of type: ForecastChartType) -> UIView {
        switch type {
        case .bar:
            return createBarChart()
        case .pie:
            return createPieChart()
        case .line:
            return createLineChart()
        }
    }

    /// Creates a bar chart view
    private static func createBarChart() -> UIView {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.separator.cgColor
        return view
    }

    /// Creates a pie chart view
    private static func createPieChart() -> UIView {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.separator.cgColor
        return view
    }

    /// Creates a line chart view
    private static func createLineChart() -> UIView {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.separator.cgColor
        return view
    }
}
