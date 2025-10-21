//
//  ForecastViewController.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 21.10.2025.
//

import UIKit
import SnapKit

final class ForecastViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: ForecastViewModel
    private let categoryRepository: CategoryRepository
    private var categoriesMap: [String: Category] = [:]

    // MARK: - UI Components

    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.backgroundColor = .systemGroupedBackground
        table.separatorStyle = .none
        table.backgroundView = UIView()
        return table
    }()

    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()

    private let monthLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        label.textAlignment = .left
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        label.textAlignment = .left
        label.text = "Прогноз загальних витрат на місяць"
        return label
    }()

    private lazy var totalCard: StatCardView = {
        let card = StatCardView(
            icon: "",
            title: "Прогнозовано",
            iconColor: .systemPurple,
            valueColor: .systemRed
        )
        return card
    }()

    private let emptyStateView: UIView = {
        let view = UIView()
        return view
    }()

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let emptyStateIconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 64)
        label.text = "📊"
        label.textAlignment = .center
        return label
    }()

    private let dataProgressView: DataProgressView = {
        let view = DataProgressView()
        return view
    }()

    private var totalCardTopConstraint: Constraint?

    // MARK: - Initialization

    init(viewModel: ForecastViewModel, categoryRepository: CategoryRepository) {
        self.viewModel = viewModel
        self.categoryRepository = categoryRepository
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
        loadCategories()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeaderViewHeight()
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Прогноз"
        view.backgroundColor = .systemGroupedBackground

        setupEmptyState()
        setupHeaderView()
        setupTableView()

        view.addSubview(tableView)
        
        setupConstraints()
    }

    private func setupHeaderView() {
        headerView.addSubview(monthLabel)
        headerView.addSubview(subtitleLabel)
        headerView.addSubview(dataProgressView)
        headerView.addSubview(totalCard)

        monthLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(monthLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }

        dataProgressView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }

        totalCard.snp.makeConstraints { make in
            totalCardTopConstraint = make.top.equalTo(dataProgressView.snp.bottom).offset(16).constraint
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-16)
        }

        // Initially hide dataProgressView
        dataProgressView.isHidden = true
        updateTotalCardPosition()

        tableView.tableHeaderView = headerView
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ForecastCell.self, forCellReuseIdentifier: ForecastCell.reuseIdentifier)
        
        tableView.backgroundView = emptyStateView
    }
    
    private func setupEmptyState() {
        emptyStateView.addSubview(emptyStateIconLabel)
        emptyStateView.addSubview(emptyStateLabel)

        emptyStateIconLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-40)
        }

        emptyStateLabel.snp.makeConstraints { make in
            make.top.equalTo(emptyStateIconLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(40)
            make.trailing.equalToSuperview().offset(-40)
        }
    }

    private func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func setupBindings() {
        viewModel.onForecastsUpdated = { [weak self] in
            self?.updateUI()
        }

        viewModel.onError = { [weak self] errorMessage in
            self?.showError(errorMessage)
        }
    }

    // MARK: - Data Loading

    private func loadCategories() {
        let result = categoryRepository.fetchAllCategories()

        switch result {
        case .success(let categories):
            for category in categories {
                if let name = category.name {
                    categoriesMap[name] = category
                }
            }
        case .failure(let error):
            print("Failed to load categories: \(error)")
        }
    }

    private func loadData() {
        viewModel.loadForecasts()
    }

    // MARK: - UI Updates

    private func updateUI() {
        monthLabel.text = viewModel.nextMonthName

        let totalAmount = viewModel.totalPredictedExpense
        totalCard.updateValue(viewModel.formattedAmount(totalAmount))

        if viewModel.isEmpty {
            emptyStateLabel.text = viewModel.errorMessage ?? "Немає даних для прогнозування"
            tableView.backgroundView?.isHidden = false
        } else {
            tableView.backgroundView?.isHidden = true
        }
        
        let shouldShowProgress = viewModel.monthsOfData > 0
        if shouldShowProgress {
            dataProgressView.configure(
                currentMonths: viewModel.monthsOfData,
                requiredMonths: 3,
                showWarning: viewModel.isBasicForecast
            )
        }

        if dataProgressView.isHidden != !shouldShowProgress {
            dataProgressView.isHidden = !shouldShowProgress
            updateTotalCardPosition()
        }

        updateHeaderViewHeight()
        
        tableView.reloadData()
    }
    
    private func updateTotalCardPosition() {
        totalCardTopConstraint?.deactivate()

        if dataProgressView.isHidden {
            totalCard.snp.makeConstraints { make in
                totalCardTopConstraint = make.top.equalTo(subtitleLabel.snp.bottom).offset(16).constraint
            }
        } else {
            totalCard.snp.makeConstraints { make in
                totalCardTopConstraint = make.top.equalTo(dataProgressView.snp.bottom).offset(16).constraint
            }
        }
    }

    private func updateHeaderViewHeight() {
        guard let header = tableView.tableHeaderView else { return }

        header.frame.size.width = tableView.bounds.width

        let newSize = header.systemLayoutSizeFitting(
            CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        )

        if header.frame.size.height != newSize.height {
            header.frame.size.height = newSize.height
            tableView.tableHeaderView = header
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Помилка",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension ForecastViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfForecasts()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ForecastCell.reuseIdentifier,
            for: indexPath
        ) as? ForecastCell,
              let forecast = viewModel.getForecast(at: indexPath.row) else {
            return UITableViewCell()
        }

        let categoryIcon = categoriesMap[forecast.categoryName]?.icon ?? "💰"
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
        return viewModel.isEmpty ? nil : "Прогноз по категоріях"
    }
}


//import UIKit
//
//final class ForecastViewController: UIViewController {
//
//    // MARK: - Properties
//
//    private let viewModel: ForecastViewModel
//    private let categoryRepository: CategoryRepository
//    private var categoriesMap: [String: Category] = [:]
//
//    // MARK: - UI Components
//
//    private let tableView: UITableView = {
//        let table = UITableView(frame: .zero, style: .grouped)
//        table.translatesAutoresizingMaskIntoConstraints = false
//        table.backgroundColor = .systemGroupedBackground
//        table.separatorStyle = .none
//        return table
//    }()
//
//    private let headerView: UIView = {
//        let view = UIView()
//        view.translatesAutoresizingMaskIntoConstraints = false
//        view.backgroundColor = .systemBackground
//        return view
//    }()
//
//    private let monthLabel: UILabel = {
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.font = .systemFont(ofSize: 28, weight: .bold)
//        label.textColor = .label
//        label.textAlignment = .center
//        return label
//    }()
//
//    private let subtitleLabel: UILabel = {
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.font = .systemFont(ofSize: 15)
//        label.textColor = .secondaryLabel
//        label.textAlignment = .center
//        label.text = "Прогноз витрат на основі AI"
//        return label
//    }()
//
//    private lazy var totalCard: StatCardView = {
//        let card = StatCardView(
//            icon: "📊",
//            title: "Прогнозовано",
//            iconColor: .systemPurple,
//            valueColor: .systemRed
//        )
//        card.translatesAutoresizingMaskIntoConstraints = false
//        return card
//    }()
//
//    private let emptyStateView: UIView = {
//        let view = UIView()
//        view.translatesAutoresizingMaskIntoConstraints = false
//        view.isHidden = true
//        return view
//    }()
//
//    private let emptyStateLabel: UILabel = {
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.font = .systemFont(ofSize: 17)
//        label.textColor = .secondaryLabel
//        label.textAlignment = .center
//        label.numberOfLines = 0
//        return label
//    }()
//
//    private let emptyStateIconLabel: UILabel = {
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.font = .systemFont(ofSize: 64)
//        label.text = "📊"
//        label.textAlignment = .center
//        return label
//    }()
//
//    private let dataProgressView: DataProgressView = {
//        let view = DataProgressView()
//        view.translatesAutoresizingMaskIntoConstraints = false
//        view.isHidden = true
//        return view
//    }()
//
//    // MARK: - Initialization
//
//    init(viewModel: ForecastViewModel, categoryRepository: CategoryRepository) {
//        self.viewModel = viewModel
//        self.categoryRepository = categoryRepository
//        super.init(nibName: nil, bundle: nil)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    // MARK: - Lifecycle
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupBindings()
//        loadCategories()
//        loadData()
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        // Оновлюємо прогноз при кожному показі екрану
//        loadData()
//    }
//
//    // MARK: - Setup
//
//    private func setupUI() {
//        title = "Прогноз"
//        view.backgroundColor = .systemGroupedBackground
//
//        // Header
//        view.addSubview(headerView)
//        headerView.addSubview(monthLabel)
//        headerView.addSubview(subtitleLabel)
//        headerView.addSubview(totalCard)
//
//        // Table view
//        view.addSubview(tableView)
//        tableView.delegate = self
//        tableView.dataSource = self
//        tableView.register(ForecastCell.self, forCellReuseIdentifier: ForecastCell.reuseIdentifier)
//
//        // Empty state
//        emptyStateView.addSubview(emptyStateIconLabel)
//        emptyStateView.addSubview(emptyStateLabel)
//        view.addSubview(emptyStateView)
//
//        // Data progress view
//        view.addSubview(dataProgressView)
//
//        setupConstraints()
//    }
//
//    private func setupConstraints() {
//        NSLayoutConstraint.activate([
//            // Header view
//            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//
//            // Month label
//            monthLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
//            monthLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
//            monthLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
//
//            // Subtitle label
//            subtitleLabel.topAnchor.constraint(equalTo: monthLabel.bottomAnchor, constant: 4),
//            subtitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
//            subtitleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
//
//            // Total card
//            totalCard.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
//            totalCard.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
//            totalCard.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
//            totalCard.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),
//
//            // Table view
//            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
//            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//
//            // Empty state
//            emptyStateView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
//            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//
//            emptyStateIconLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
//            emptyStateIconLabel.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor, constant: -40),
//
//            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateIconLabel.bottomAnchor, constant: 16),
//            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 40),
//            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -40),
//
//            // Data progress view
//            dataProgressView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
//            dataProgressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            dataProgressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
//        ])
//    }
//
//    private func setupBindings() {
//        viewModel.onForecastsUpdated = { [weak self] in
//            self?.updateUI()
//        }
//
//        viewModel.onError = { [weak self] errorMessage in
//            self?.showError(errorMessage)
//        }
//    }
//
//    // MARK: - Data Loading
//
//    private func loadCategories() {
//        let result = categoryRepository.fetchAllCategories()
//
//        switch result {
//        case .success(let categories):
//            for category in categories {
//                if let name = category.name {
//                    categoriesMap[name] = category
//                }
//            }
//        case .failure(let error):
//            print("Failed to load categories: \(error)")
//        }
//    }
//
//    private func loadData() {
//        viewModel.loadForecasts()
//    }
//
//    // MARK: - UI Updates
//
//    private func updateUI() {
//        monthLabel.text = viewModel.nextMonthName
//
//        // Update total card
//        let totalAmount = viewModel.totalPredictedExpense
//        totalCard.updateValue(viewModel.formattedAmount(totalAmount))
//
//        // Показуємо прогрес якщо є хоч якісь дані але менше 3 місяців
//        if viewModel.monthsOfData > 0 && viewModel.monthsOfData < 3 {
//            showDataProgress()
//        } else if viewModel.isEmpty {
//            showEmptyState()
//        } else {
//            hideAllStates()
//        }
//
//        // Показуємо попередження якщо використовується базовий прогноз
//        if viewModel.isBasicForecast && !viewModel.isEmpty {
//            subtitleLabel.text = "⚠️ Спрощений прогноз (недостатньо даних для AI)"
//            subtitleLabel.textColor = .systemOrange
//        } else {
//            subtitleLabel.text = "Прогноз витрат на основі AI"
//            subtitleLabel.textColor = .secondaryLabel
//        }
//
//        tableView.reloadData()
//    }
//
//    private func showEmptyState() {
//        emptyStateLabel.text = viewModel.errorMessage ?? "Немає даних для прогнозування"
//        emptyStateView.isHidden = false
//        tableView.isHidden = true
//        dataProgressView.isHidden = true
//    }
//
//    private func showDataProgress() {
//        dataProgressView.configure(
//            currentMonths: viewModel.monthsOfData,
//            requiredMonths: 3,
//            showWarning: viewModel.isBasicForecast
//        )
//        dataProgressView.isHidden = false
//        emptyStateView.isHidden = true
//        tableView.isHidden = false
//    }
//
//    private func hideAllStates() {
//        emptyStateView.isHidden = true
//        dataProgressView.isHidden = true
//        tableView.isHidden = false
//    }
//
//    private func showError(_ message: String) {
//        let alert = UIAlertController(
//            title: "Помилка",
//            message: message,
//            preferredStyle: .alert
//        )
//        alert.addAction(UIAlertAction(title: "OK", style: .default))
//        present(alert, animated: true)
//    }
//}
//
//// MARK: - UITableViewDataSource
//
//extension ForecastViewController: UITableViewDataSource {
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return viewModel.numberOfForecasts()
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        guard let cell = tableView.dequeueReusableCell(
//            withIdentifier: ForecastCell.reuseIdentifier,
//            for: indexPath
//        ) as? ForecastCell,
//              let forecast = viewModel.getForecast(at: indexPath.row) else {
//            return UITableViewCell()
//        }
//
//        // Отримуємо іконку категорії
//        let categoryIcon = categoriesMap[forecast.categoryName]?.icon ?? "💰"
//
//        cell.configure(with: forecast, categoryIcon: categoryIcon, viewModel: viewModel)
//
//        return cell
//    }
//}
//
//// MARK: - UITableViewDelegate
//
//extension ForecastViewController: UITableViewDelegate {
//
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return UITableView.automaticDimension
//    }
//
//    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 100
//    }
//
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        return viewModel.isEmpty ? nil : "Прогноз по категоріях"
//    }
//}
