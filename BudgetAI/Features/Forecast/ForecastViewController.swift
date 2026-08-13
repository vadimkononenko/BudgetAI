//
//  ForecastViewController.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 21.10.2025.
//  Refactored by Vadim Kononenko on 14.11.2025.
//

import UIKit
import SnapKit

/// Main view controller for displaying expense forecasts
/// Coordinates between UI components, data formatting, and chart management
final class ForecastViewController: UIViewController {

    // MARK: - Properties

    /// View model providing forecast data and business logic
    private let viewModel: ForecastViewModel

    /// Manages UI component creation and layout
    private let uiBuilder: ForecastUIBuilder

    /// Formats data for display
    private let dataFormatter: ForecastDataFormatter

    /// Manages chart-related functionality
    private let chartManager: ForecastChartManager

    // MARK: - Initialization

    /// Initializes the forecast view controller with required dependencies
    /// - Parameters:
    ///   - viewModel: The forecast view model
    ///   - categoryRepository: Repository for accessing category data
    init(viewModel: ForecastViewModel, categoryRepository: CategoryRepository) {
        self.viewModel = viewModel
        self.uiBuilder = ForecastUIBuilder()
        self.dataFormatter = ForecastDataFormatter(viewModel: viewModel, categoryRepository: categoryRepository)
        self.chartManager = ForecastChartManager(dataFormatter: dataFormatter, uiBuilder: uiBuilder)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        dataFormatter.loadCategories()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        chartManager.updateHeaderHeight(for: uiBuilder.tableView)
    }

    // MARK: - Setup

    /// Configures the view hierarchy and appearance
    private func setupUI() {
        title = L10n.Forecast.title
        view.backgroundColor = .systemGroupedBackground

        setupTableView()
        setupConstraints()
    }

    /// Configures the table view with header and empty state
    private func setupTableView() {
        uiBuilder.configureTableView(delegate: self, dataSource: self)
        uiBuilder.tableView.tableHeaderView = uiBuilder.buildHeaderView()
        _ = uiBuilder.buildEmptyStateView()

        view.addSubview(uiBuilder.tableView)
    }

    /// Sets up Auto Layout constraints for the main view
    private func setupConstraints() {
        uiBuilder.tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    /// Establishes bindings between view model and view controller
    private func setupBindings() {
        viewModel.onForecastsUpdated = { [weak self] in
            self?.updateUI()
        }

        viewModel.onError = { [weak self] errorMessage in
            self?.showError(errorMessage)
        }
    }

    // MARK: - Data Loading

    /// Triggers forecast data loading from view model
    private func loadData() {
        viewModel.loadForecasts()
    }

    // MARK: - UI Updates

    /// Updates all UI components with current forecast data
    private func updateUI() {
        updateHeaderLabels()
        chartManager.updateCharts()
        chartManager.configureDataProgressView()
        chartManager.toggleEmptyState(for: uiBuilder.tableView)
        chartManager.updateHeaderHeight(for: uiBuilder.tableView)

        uiBuilder.tableView.reloadData()
    }

    /// Updates the header section labels with formatted data
    private func updateHeaderLabels() {
        uiBuilder.monthLabel.text = chartManager.getMonthText()
        uiBuilder.subtitleLabel.text = chartManager.getSubtitleText()
        uiBuilder.subtitleLabel.textColor = chartManager.getSubtitleColor()
    }

    /// Presents an error alert to the user
    /// - Parameter message: The error message to display
    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: L10n.Common.error,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.Common.ok, style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension ForecastViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataFormatter.getNumberOfForecasts()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ForecastCell.reuseIdentifier,
            for: indexPath
        ) as? ForecastCell,
              let forecast = dataFormatter.getForecast(at: indexPath.row) else {
            return UITableViewCell()
        }

        let categoryIcon = dataFormatter.getCategoryIcon(for: forecast.categoryName)
        cell.configure(with: forecast, categoryIcon: categoryIcon, viewModel: viewModel)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ForecastViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dataFormatter.getSectionHeaderTitle()
    }
}
