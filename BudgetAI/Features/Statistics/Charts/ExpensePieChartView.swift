//
//  ExpensePieChartView.swift
//  BudgetAI
//
//  Created by Vadim Kononenko
//

import UIKit
import SwiftUI
import Charts

/// SwiftUI view displaying a pie chart of expenses broken down by category
struct ExpensePieChartView: View {
    // MARK: - Properties

    let categoryStats: [CategoryStatDisplayModel]
    let onCategoryTap: ((Category) -> Void)?

    @State private var selectedCategory: String?

    // MARK: - Body

    var body: some View {
        ChartStyleConfigurator.chartContainer {
            VStack(alignment: .leading, spacing: ChartStyleConfigurator.standardVerticalSpacing) {
                Text(L10n.Statistics.expenseDistribution)
                    .font(ChartStyleConfigurator.titleFont)
                    .foregroundColor(Color(uiColor: .label))
                    .padding(.horizontal, ChartStyleConfigurator.standardHorizontalPadding)

                if categoryStats.isEmpty {
                    ChartStyleConfigurator.emptyStateView(
                        iconName: "chart.pie.fill",
                        message: L10n.Statistics.noData,
                        height: ChartStyleConfigurator.standardChartHeight
                    )
                } else {
                    pieChartView
                    legendView
                }
            }
        }
    }

    // MARK: - Pie Chart View

    /// Main pie chart displaying category expense distribution
    private var pieChartView: some View {
        Chart(categoryStats, id: \.categoryName) { stat in
            SectorMark(
                angle: .value("Amount", stat.amountRaw),
                innerRadius: .ratio(0.5),
                angularInset: 1.5
            )
            .foregroundStyle(Color(stat.categoryColor))
            .opacity(selectedCategory == nil || selectedCategory == stat.categoryName ? 1.0 : 0.3)
        }
        .chartAngleSelection(value: $selectedCategory)
        .frame(height: ChartStyleConfigurator.standardChartHeight)
        .padding(.horizontal, ChartStyleConfigurator.standardHorizontalPadding)
        .onChange(of: selectedCategory) { oldValue, newValue in
            if let categoryName = newValue,
               let stat = categoryStats.first(where: { $0.categoryName == categoryName }) {
                onCategoryTap?(stat.category)
            }
        }
    }

    // MARK: - Legend View

    /// Scrollable legend displaying all categories with amounts and percentages
    private var legendView: some View {
        VStack(spacing: 12) {
            HStack {
                Text(L10n.Transaction.category)
                    .font(ChartStyleConfigurator.sectionHeaderFont)
                    .foregroundColor(Color(uiColor: .label))
                Spacer()
                Text("\(categoryStats.count)")
                    .font(ChartStyleConfigurator.dataLabelFont)
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            }
            .padding(.horizontal, ChartStyleConfigurator.standardHorizontalPadding)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 8) {
                    ForEach(Array(categoryStats.enumerated()), id: \.element.categoryName) { index, stat in
                        categoryRow(for: stat)
                    }
                }
            }
            .frame(maxHeight: ChartStyleConfigurator.legendMaxHeight)
        }
    }

    // MARK: - Category Row

    /// Creates a single row in the legend for a category
    /// - Parameter stat: The category statistics to display
    /// - Returns: Category row view
    private func categoryRow(for stat: CategoryStatDisplayModel) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(stat.categoryColor))
                .frame(width: 12, height: 12)

            Text(stat.categoryIcon)
                .font(.system(size: 16))

            Text(stat.categoryName)
                .font(ChartStyleConfigurator.dataLabelFont)
                .foregroundColor(Color(uiColor: .label))

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(stat.amount)
                    .font(ChartStyleConfigurator.mediumValueFont)
                    .foregroundColor(Color(uiColor: .label))

                Text(stat.percentageText)
                    .font(ChartStyleConfigurator.smallDataLabelFont)
                    .foregroundColor(Color(uiColor: .secondaryLabel))
            }
        }
        .padding(.horizontal, ChartStyleConfigurator.standardHorizontalPadding)
        .padding(.vertical, 4)
        .opacity(selectedCategory == nil || selectedCategory == stat.categoryName ? 1.0 : 0.5)
    }
}

// MARK: - UIKit Wrapper

/// UIKit wrapper for ExpensePieChartView to enable usage in UIKit-based views
final class ExpensePieChartViewController: UIViewController {

    // MARK: - Properties

    private var categoryStats: [CategoryStatDisplayModel]
    private var onCategoryTap: ((Category) -> Void)?

    // MARK: - Initialization

    /// Initializes the view controller with category statistics
    /// - Parameters:
    ///   - categoryStats: Array of category expense statistics to display
    ///   - onCategoryTap: Optional callback when a category is tapped
    init(categoryStats: [CategoryStatDisplayModel], onCategoryTap: ((Category) -> Void)? = nil) {
        self.categoryStats = categoryStats
        self.onCategoryTap = onCategoryTap
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

    /// Updates the chart with new category statistics
    /// - Parameter categoryStats: New array of category expense statistics
    func updateData(_ categoryStats: [CategoryStatDisplayModel]) {
        self.categoryStats = categoryStats
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

        let chartView = ExpensePieChartView(
            categoryStats: categoryStats,
            onCategoryTap: onCategoryTap
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
