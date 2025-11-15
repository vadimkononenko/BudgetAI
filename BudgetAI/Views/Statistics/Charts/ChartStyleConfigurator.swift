//
//  ChartStyleConfigurator.swift
//  BudgetAI
//
//  Created by Vadim Kononenko
//

import SwiftUI
import Charts

/// Shared configuration and styling utilities for all chart views in the application.
/// Provides consistent colors, fonts, layouts, and formatting across different chart types.
struct ChartStyleConfigurator {

    // MARK: - Chart Dimensions

    /// Standard height for bar and line charts
    static let standardChartHeight: CGFloat = 280

    /// Standard height for trend line charts
    static let trendChartHeight: CGFloat = 240

    /// Maximum height for scrollable legend views
    static let legendMaxHeight: CGFloat = 200

    // MARK: - Colors

    /// Color used for income or positive values
    static let incomeColor = Color.green

    /// Color used for expenses or negative values
    static let expenseColor = Color.red

    /// Color used for selection indicators
    static let selectionColor = Color.gray.opacity(0.5)

    // MARK: - Fonts

    /// Font for chart titles
    static let titleFont = Font.system(size: 20, weight: .bold)

    /// Font for axis labels
    static let axisLabelFont = Font.system(size: 10)

    /// Font for section headers
    static let sectionHeaderFont = Font.system(size: 16, weight: .semibold)

    /// Font for secondary headers
    static let secondaryHeaderFont = Font.system(size: 14, weight: .semibold)

    /// Font for data labels
    static let dataLabelFont = Font.system(size: 14, weight: .medium)

    /// Font for small data labels
    static let smallDataLabelFont = Font.system(size: 12)

    /// Font for extra small labels
    static let extraSmallLabelFont = Font.system(size: 11)

    /// Font for large data values
    static let largeValueFont = Font.system(size: 16, weight: .semibold)

    /// Font for medium data values
    static let mediumValueFont = Font.system(size: 14, weight: .semibold)

    /// Font for small data values
    static let smallValueFont = Font.system(size: 13, weight: .medium)

    // MARK: - Spacing

    /// Standard vertical spacing between elements
    static let standardVerticalSpacing: CGFloat = 16

    /// Standard horizontal padding
    static let standardHorizontalPadding: CGFloat = 16

    /// Standard corner radius for containers
    static let standardCornerRadius: CGFloat = 12

    /// Small corner radius for nested elements
    static let smallCornerRadius: CGFloat = 8

    // MARK: - Amount Formatting

    /// Formats large amounts with 'k' suffix for thousands
    /// - Parameter amount: The amount to format
    /// - Returns: Formatted string with thousands abbreviated
    static func formatAmount(_ amount: Double) -> String {
        if amount >= 10000 {
            return String(format: "%.0fk", amount / 1000)
        } else if amount >= 1000 {
            return String(format: "%.1fk", amount / 1000)
        } else {
            return String(format: "%.0f", amount)
        }
    }

    // MARK: - Empty State View

    /// Creates a consistent empty state view for charts with no data
    /// - Parameters:
    ///   - iconName: SF Symbol name for the icon
    ///   - message: Message to display
    ///   - height: Height of the empty state view
    /// - Returns: View displaying empty state
    static func emptyStateView(
        iconName: String,
        message: String,
        height: CGFloat
    ) -> some View {
        VStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Chart Container

    /// Creates a consistent container view for charts
    /// - Parameter content: The chart content to wrap
    /// - Returns: Styled container view
    static func chartContainer<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(.vertical, standardVerticalSpacing)
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(standardCornerRadius)
            .padding(.horizontal, standardHorizontalPadding)
    }

    // MARK: - Info Card

    /// Creates a styled information card for selected data
    /// - Parameter content: The content to display in the card
    /// - Returns: Styled info card view
    static func infoCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(12)
            .background(Color(uiColor: .tertiarySystemBackground))
            .cornerRadius(smallCornerRadius)
            .padding(.horizontal, standardHorizontalPadding)
    }

    // MARK: - Date Formatting

    /// Formats a date based on the period filter
    /// - Parameters:
    ///   - date: The date to format
    ///   - period: The period filter determining the format
    /// - Returns: Formatted date string
    static func formatDate(_ date: Date, for period: StatisticsViewModel.PeriodFilter) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")

        switch period {
        case .currentMonth, .specificMonth:
            formatter.dateFormat = "d MMMM yyyy"
        case .currentYear, .allTime:
            formatter.dateFormat = "LLLL yyyy"
        }

        return formatter.string(from: date).capitalized
    }

    /// Formats a date as month and year
    /// - Parameter date: The date to format
    /// - Returns: Formatted string with month and year
    static func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date).capitalized
    }

    // MARK: - Chart Axis Configuration

    /// Returns the appropriate time unit for chart X-axis based on period
    /// - Parameter period: The period filter
    /// - Returns: Calendar component for the time unit
    static func timeUnit(for period: StatisticsViewModel.PeriodFilter) -> Calendar.Component {
        switch period {
        case .currentMonth, .specificMonth:
            return .day
        case .currentYear, .allTime:
            return .month
        }
    }

    /// Returns the date format style for chart X-axis based on period
    /// - Parameter period: The period filter
    /// - Returns: Date format style for axis labels
    static func dateFormatStyle(for period: StatisticsViewModel.PeriodFilter) -> Date.FormatStyle {
        switch period {
        case .currentMonth, .specificMonth:
            return .dateTime.day().month(.abbreviated)
        case .currentYear, .allTime:
            return .dateTime.month(.abbreviated).year()
        }
    }

    // MARK: - Y-Axis Configuration

    /// Creates a consistent Y-axis configuration for charts
    /// - Returns: Axis marks configuration
    static func yAxisMarks() -> some AxisContent {
        AxisMarks(position: .leading) { value in
            AxisGridLine()
            AxisValueLabel {
                if let amount = value.as(Double.self) {
                    Text(formatAmount(amount))
                        .font(axisLabelFont)
                }
            }
        }
    }

    // MARK: - Data Value Views

    /// Creates a vertical stack displaying a label and value
    /// - Parameters:
    ///   - label: The label text
    ///   - value: The value text
    ///   - valueColor: Color for the value text
    ///   - alignment: Alignment of the stack
    /// - Returns: Styled data value view
    static func dataValueView(
        label: String,
        value: String,
        valueColor: Color,
        alignment: HorizontalAlignment = .leading
    ) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(label)
                .font(smallDataLabelFont)
                .foregroundColor(Color(uiColor: .secondaryLabel))
            Text(value)
                .font(mediumValueFont)
                .foregroundColor(valueColor)
        }
    }

    /// Creates a compact data value view with smaller fonts
    /// - Parameters:
    ///   - label: The label text
    ///   - value: The value text
    ///   - valueColor: Color for the value text
    /// - Returns: Compact styled data value view
    static func compactDataValueView(
        label: String,
        value: String,
        valueColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(extraSmallLabelFont)
                .foregroundColor(Color(uiColor: .secondaryLabel))
            Text(value)
                .font(smallValueFont)
                .foregroundColor(valueColor)
        }
    }

    // MARK: - Gradient Styles

    /// Creates a gradient for area charts
    /// - Parameter baseColor: The base color for the gradient
    /// - Returns: Linear gradient from color to transparent
    static func areaGradient(baseColor: Color) -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                baseColor.opacity(0.3),
                baseColor.opacity(0.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
