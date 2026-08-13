//
//  StatisticsViewController.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//  Refactored by Vadim Kononenko on 14.11.2025.
//

import UIKit
import SnapKit

/// Main view controller for displaying financial statistics
/// Shows income, expenses, balance cards, charts, and category breakdowns
final class StatisticsViewController: UIViewController {

    // MARK: - Properties

    /// View model that manages statistics data and business logic
    private let viewModel: StatisticsViewModel

    /// Manager responsible for chart view controllers
    private var chartManager: StatisticsChartManager?

    // MARK: - UI Components

    /// Main scroll view containing all statistics content
    private lazy var scrollView = UIScrollView()

    /// Content view inside scroll view
    private lazy var contentView = UIView()

    /// Button for selecting time period with dropdown menu
    private lazy var periodFilterButton: UIButton = {
        return StatisticsUIBuilder.makePeriodFilterButton()
    }()

    /// Card displaying income information
    private lazy var incomeCard = StatisticsUIBuilder.makeIncomeCard()

    /// Card displaying expense information
    private lazy var expenseCard = StatisticsUIBuilder.makeExpenseCard()

    /// Card displaying balance information
    private lazy var balanceCard = StatisticsUIBuilder.makeBalanceCard()

    /// View for filtering statistics by category
    private lazy var categoryFilterView: CategoryFilterView = {
        let view = CategoryFilterView()
        view.onFilterChanged = { [weak self] selectedCategories in
            self?.handleCategoryFilterChanged(selectedCategories)
        }
        return view
    }()

    /// Title label for category statistics section
    private lazy var categoryStatsTitleLabel = StatisticsUIBuilder.makeLabel(
        text: L10n.Statistics.topCategories,
        font: .systemFont(ofSize: 20, weight: .bold),
        color: .label
    )

    /// Table view displaying category statistics
    private lazy var categoryStatsTableView: UITableView = {
        return StatisticsUIBuilder.makeCategoryStatsTableView(
            delegate: self,
            dataSource: self
        )
    }()

    /// Button to show all categories
    private lazy var showMoreButton: UIButton = {
        return StatisticsUIBuilder.makeShowMoreButton(
            target: self,
            action: #selector(showMoreButtonTapped)
        )
    }()

    /// Label displayed when no data is available
    private lazy var emptyStateLabel = StatisticsUIBuilder.makeEmptyStateLabel()

    /// Spacer view at the bottom for proper scroll view content size
    private lazy var bottomSpacerView = UIView()

    // MARK: - Initialization

    /// Initializes the view controller with a view model
    /// - Parameter viewModel: The statistics view model
    init(viewModel: StatisticsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        // For Storyboard compatibility (not used)
        self.viewModel = DIContainer.shared.makeStatisticsViewModel()
        super.init(coder: coder)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        viewModel.loadAvailableMonths()
        updatePeriodFilterMenu()
        viewModel.fetchData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadAvailableMonths()
        updatePeriodFilterMenu()
        viewModel.fetchData()
    }

    // MARK: - Setup

    /// Sets up view model bindings for data updates and error handling
    private func setupBindings() {
        viewModel.onDataUpdated = { [weak self] in
            self?.updateUI()
        }

        viewModel.onError = { [weak self] error in
            guard let self = self else { return }
            ErrorPresenter.show(error, in: self)
        }
    }

    /// Sets up the user interface and layout
    private func setupUI() {
        configureNavigationBar()
        addSubviews()
        setupCharts()
        setupConstraints()
    }

    /// Configures navigation bar appearance and items
    private func configureNavigationBar() {
        title = L10n.Statistics.title
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.titleView = periodFilterButton
    }

    /// Adds all subviews to the view hierarchy
    private func addSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(incomeCard)
        contentView.addSubview(expenseCard)
        contentView.addSubview(balanceCard)
        contentView.addSubview(categoryFilterView)
        contentView.addSubview(categoryStatsTitleLabel)
        contentView.addSubview(categoryStatsTableView)
        contentView.addSubview(showMoreButton)
        contentView.addSubview(emptyStateLabel)
        contentView.addSubview(bottomSpacerView)
    }

    /// Sets up chart view controllers using chart manager
    private func setupCharts() {
        chartManager = StatisticsChartManager(
            parentViewController: self,
            containerView: contentView
        )

        chartManager?.setupCharts(
            categoryStats: viewModel.getFilteredCategoryStats(),
            dailyExpenses: viewModel.getDailyExpenses(),
            monthlyData: viewModel.getMonthlyComparisonData(),
            selectedPeriod: viewModel.selectedPeriod,
            topAnchor: categoryFilterView,
            onCategoryTap: { [weak self] category in
                self?.handleCategoryTap(category)
            }
        )
    }

    /// Sets up all layout constraints
    private func setupConstraints() {
        // Scroll View
        StatisticsUIBuilder.setupScrollView(
            scrollView,
            contentView: contentView,
            in: view
        )

        // Cards
        StatisticsUIBuilder.setupCardsLayout(
            incomeCard: incomeCard,
            expenseCard: expenseCard,
            balanceCard: balanceCard,
            in: contentView
        )

        // Category Filter
        categoryFilterView.snp.makeConstraints { make in
            make.top.equalTo(balanceCard.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        // Category Stats Section
        if let bottomChartView = chartManager?.getBottomChartView() {
            StatisticsUIBuilder.setupCategoryStatsLayout(
                titleLabel: categoryStatsTitleLabel,
                tableView: categoryStatsTableView,
                showMoreButton: showMoreButton,
                emptyStateLabel: emptyStateLabel,
                bottomSpacerView: bottomSpacerView,
                topAnchor: bottomChartView,
                in: contentView
            )
        }
    }

    // MARK: - Period Filter

    /// Updates the period filter menu with available options
    private func updatePeriodFilterMenu() {
        let menuItems = viewModel.getPeriodMenuItems()

        // Group menu items by type
        let currentMonthItems = menuItems.filter {
            if case .currentMonth = $0.period { return true }
            return false
        }

        let specificMonthItems = menuItems.filter {
            if case .specificMonth = $0.period { return true }
            return false
        }

        let currentYearItems = menuItems.filter {
            if case .currentYear = $0.period { return true }
            return false
        }

        let allTimeItems = menuItems.filter {
            if case .allTime = $0.period { return true }
            return false
        }

        var menuChildren: [UIMenuElement] = []

        // Add current month
        menuChildren.append(contentsOf: currentMonthItems.map { createMenuAction(for: $0) })

        // Add specific months as submenu if available
        if !specificMonthItems.isEmpty {
            let specificMonthActions = specificMonthItems.map { createMenuAction(for: $0) }
            let specificMonthMenu = UIMenu(title: L10n.Statistics.selectMonth, children: specificMonthActions)
            menuChildren.append(specificMonthMenu)
        }

        // Add current year and all time
        menuChildren.append(contentsOf: currentYearItems.map { createMenuAction(for: $0) })
        menuChildren.append(contentsOf: allTimeItems.map { createMenuAction(for: $0) })

        periodFilterButton.menu = UIMenu(children: menuChildren)
    }

    /// Creates a menu action for a period menu item
    /// - Parameter item: The period menu item
    /// - Returns: UIAction configured for the menu item
    private func createMenuAction(for item: StatisticsViewModel.PeriodMenuItem) -> UIAction {
        return UIAction(
            title: item.title,
            image: item.isSelected ? UIImage(systemName: "checkmark") : nil
        ) { [weak self] _ in
            self?.handlePeriodSelected(item)
        }
    }

    /// Handles period selection from menu
    /// - Parameter item: The selected period menu item
    private func handlePeriodSelected(_ item: StatisticsViewModel.PeriodMenuItem) {
        viewModel.setPeriod(item.period)
        periodFilterButton.configuration?.title = item.title
        updatePeriodFilterMenu()
    }

    // MARK: - Category Filter

    /// Handles category filter changes
    /// - Parameter selectedCategories: Array of selected category names
    private func handleCategoryFilterChanged(_ selectedCategories: [String]) {
        viewModel.selectedCategories = Set(selectedCategories)
        viewModel.fetchData()
    }

    /// Handles category tap from pie chart
    /// - Parameter category: The tapped category name
    private func handleCategoryTap(_ category: Category) {
        let dateRange = viewModel.getDateRange()
        let detailVC = BudgetDetailViewController(
            category: category,
            startDate: dateRange.startDate,
            endDate: dateRange.endDate
        )
        navigationController?.pushViewController(detailVC, animated: true)
    }

    // MARK: - UI Updates

    /// Updates all UI components with current data
    private func updateUI() {
        updateCards()
        updateCategoryFilter()
        updateCharts()
        updateCategoryStats()
        updateVisibility()
    }

    /// Updates statistics cards with current values
    private func updateCards() {
        incomeCard.updateValue(viewModel.getFormattedIncome())
        expenseCard.updateValue(viewModel.getFormattedExpenses())
        balanceCard.updateValue(
            viewModel.getFormattedBalance(),
            color: viewModel.getBalanceColor()
        )
    }

    /// Updates category filter view with available categories
    private func updateCategoryFilter() {
        categoryFilterView.configure(
            categories: viewModel.allCategoryStats,
            selectedCategories: viewModel.selectedCategories
        )
    }

    /// Updates all charts with current data
    private func updateCharts() {
        chartManager?.updateCharts(
            categoryStats: viewModel.getFilteredCategoryStats(),
            dailyExpenses: viewModel.getDailyExpenses(),
            monthlyData: viewModel.getMonthlyComparisonData(),
            selectedPeriod: viewModel.selectedPeriod
        )
    }

    /// Updates category statistics table view
    private func updateCategoryStats() {
        let tableHeight = CGFloat(viewModel.topCategoryStats.count * 60)
        categoryStatsTableView.snp.updateConstraints { make in
            make.height.equalTo(tableHeight)
        }
        categoryStatsTableView.reloadData()
    }

    /// Updates visibility of UI components based on data availability
    private func updateVisibility() {
        let hasData = viewModel.hasData()

        emptyStateLabel.isHidden = hasData
        categoryStatsTableView.isHidden = !hasData
        categoryStatsTitleLabel.isHidden = !hasData
        showMoreButton.isHidden = !(hasData && viewModel.hasMoreThan5Categories())

        categoryFilterView.isHidden = viewModel.allCategoryStats.isEmpty
        chartManager?.setChartsVisibility(hasData)

        // Update bottom spacer constraint
        StatisticsUIBuilder.updateBottomSpacerConstraint(
            bottomSpacerView: bottomSpacerView,
            showMoreButton: showMoreButton,
            tableView: categoryStatsTableView
        )
    }

    // MARK: - Actions

    /// Handles show more button tap to display all categories
    @objc private func showMoreButtonTapped() {
        let allCategoryVC = AllCategoryStatsViewController(
            categoryStats: viewModel.allCategoryStats,
            totalExpense: viewModel.totalExpenses,
            selectedPeriod: viewModel.selectedPeriod
        )
        navigationController?.pushViewController(allCategoryVC, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension StatisticsViewController: UITableViewDataSource {

    /// Returns the number of category statistics to display
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.topCategoryStats.count
    }

    /// Configures and returns a cell for the given index path
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CategoryStatCell.reuseIdentifier,
            for: indexPath
        ) as? CategoryStatCell else {
            return UITableViewCell()
        }

        let stat = viewModel.topCategoryStats[indexPath.row]
        cell.configure(with: stat)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension StatisticsViewController: UITableViewDelegate {

    /// Returns the height for each category statistics row
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    /// Handles row selection to show category details
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let category = viewModel.getCategory(at: indexPath.row) else { return }
        let dateRange = viewModel.getDateRange()

        let detailVC = BudgetDetailViewController(
            category: category,
            startDate: dateRange.startDate,
            endDate: dateRange.endDate
        )
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
