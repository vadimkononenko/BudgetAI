//
//  StatisticsViewController.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import UIKit
import SnapKit

final class StatisticsViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: StatisticsViewModel

    // MARK: - UI Components

    private lazy var scrollView = UIScrollView()
    private lazy var contentView = UIView()

    private lazy var periodFilterButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.plain()

        configuration.title = "Поточний місяць"
        configuration.baseForegroundColor = .label

        configuration.image = UIImage(systemName: "calendar", withConfiguration: UIImage.SymbolConfiguration(weight: .medium))
        configuration.imagePlacement = .leading
        configuration.imagePadding = 6.0

        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 15, weight: .medium)
            return outgoing
        }

        button.configuration = configuration
        button.showsMenuAsPrimaryAction = true
        return button
    }()

    private lazy var incomeCard = StatCardView(icon: "↑", title: "Доходи", iconColor: .systemGreen, valueColor: .systemGreen)
    private lazy var expenseCard = StatCardView(icon: "↓", title: "Витрати", iconColor: .systemRed, valueColor: .systemRed)
    private lazy var balanceCard = StatCardView(icon: "=", title: "Баланс", iconColor: .label, valueColor: .label)

    private lazy var categoryStatsTitleLabel = makeLabel(text: "Топ-5 категорій витрат", font: .systemFont(ofSize: 20, weight: .bold), color: .label)

    private lazy var categoryStatsTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.register(CategoryStatCell.self, forCellReuseIdentifier: CategoryStatCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    private lazy var showMoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Показати більше", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.setTitleColor(.systemBlue, for: .normal)
        button.addTarget(self, action: #selector(showMoreButtonTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    private lazy var emptyStateLabel: UILabel = {
        let label = makeLabel(text: "Немає даних для відображення статистики", font: .systemFont(ofSize: 16), color: .secondaryLabel, alignment: .center, lines: 0)
        label.isHidden = true
        return label
    }()

    private lazy var bottomSpacerView = UIView()

    // MARK: - Initialization

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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadAvailableMonths()
        updatePeriodFilterMenu()
        viewModel.fetchData()
    }

    // MARK: - Setup

    private func makeLabel(text: String, font: UIFont, color: UIColor, alignment: NSTextAlignment = .left, lines: Int = 1) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = color
        label.textAlignment = alignment
        label.numberOfLines = lines
        return label
    }

    private func setupBindings() {
        viewModel.onDataUpdated = { [weak self] in
            self?.updateUI()
        }

        viewModel.onError = { [weak self] error in
            guard let self = self else { return }
            ErrorPresenter.show(error, in: self)
        }
    }

    private func setupUI() {
        title = "Статистика"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true

        navigationItem.titleView = periodFilterButton

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(incomeCard)
        contentView.addSubview(expenseCard)
        contentView.addSubview(balanceCard)
        contentView.addSubview(categoryStatsTitleLabel)
        contentView.addSubview(categoryStatsTableView)
        contentView.addSubview(showMoreButton)
        contentView.addSubview(emptyStateLabel)
        contentView.addSubview(bottomSpacerView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        incomeCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(70)
        }

        expenseCard.snp.makeConstraints { make in
            make.top.equalTo(incomeCard.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(70)
        }

        balanceCard.snp.makeConstraints { make in
            make.top.equalTo(expenseCard.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(70)
        }

        categoryStatsTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(balanceCard.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        categoryStatsTableView.snp.makeConstraints { make in
            make.top.equalTo(categoryStatsTitleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0)
        }

        showMoreButton.snp.makeConstraints { make in
            make.top.equalTo(categoryStatsTableView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.height.equalTo(44)
        }

        emptyStateLabel.snp.makeConstraints { make in
            make.top.equalTo(categoryStatsTitleLabel.snp.bottom).offset(40)
            make.leading.trailing.equalToSuperview().inset(40)
        }

        bottomSpacerView.snp.makeConstraints { make in
            make.top.equalTo(showMoreButton.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0)
            make.bottom.equalToSuperview()
        }
    }


    private func updatePeriodFilterMenu() {
        let menuItems = viewModel.getPeriodMenuItems()

        // Group specific months separately
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
        for item in currentMonthItems {
            let action = createMenuAction(for: item)
            menuChildren.append(action)
        }

        // Add specific months as submenu if available
        if !specificMonthItems.isEmpty {
            let specificMonthActions = specificMonthItems.map { createMenuAction(for: $0) }
            let specificMonthMenu = UIMenu(title: "Вибрати місяць", children: specificMonthActions)
            menuChildren.append(specificMonthMenu)
        }

        // Add current year
        for item in currentYearItems {
            let action = createMenuAction(for: item)
            menuChildren.append(action)
        }

        // Add all time
        for item in allTimeItems {
            let action = createMenuAction(for: item)
            menuChildren.append(action)
        }

        periodFilterButton.menu = UIMenu(children: menuChildren)
    }

    private func createMenuAction(for item: StatisticsViewModel.PeriodMenuItem) -> UIAction {
        return UIAction(
            title: item.title,
            image: item.isSelected ? UIImage(systemName: "checkmark") : nil
        ) { [weak self] _ in
            self?.viewModel.setPeriod(item.period)
            self?.periodFilterButton.configuration?.title = item.title
            self?.updatePeriodFilterMenu()
        }
    }


    private func updateUI() {
        incomeCard.updateValue(viewModel.getFormattedIncome())
        expenseCard.updateValue(viewModel.getFormattedExpenses())
        balanceCard.updateValue(viewModel.getFormattedBalance(), color: viewModel.getBalanceColor())

        let tableHeight = CGFloat(viewModel.topCategoryStats.count * 60)
        categoryStatsTableView.snp.updateConstraints { make in
            make.height.equalTo(tableHeight)
        }

        categoryStatsTableView.reloadData()

        let hasData = viewModel.hasData()
        emptyStateLabel.isHidden = hasData
        categoryStatsTableView.isHidden = !hasData
        categoryStatsTitleLabel.isHidden = !hasData
        showMoreButton.isHidden = !(hasData && viewModel.hasMoreThan5Categories())

        // Update bottomSpacerView constraint based on showMoreButton visibility
        bottomSpacerView.snp.remakeConstraints { make in
            if showMoreButton.isHidden {
                make.top.equalTo(categoryStatsTableView.snp.bottom).offset(20)
            } else {
                make.top.equalTo(showMoreButton.snp.bottom).offset(20)
            }
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0)
            make.bottom.equalToSuperview()
        }
    }

    // MARK: - Actions

    @objc private func showMoreButtonTapped() {
        let allCategoryVC = AllCategoryStatsViewController(categoryStats: viewModel.allCategoryStats, totalExpense: viewModel.totalExpenses, selectedPeriod: viewModel.selectedPeriod)
        navigationController?.pushViewController(allCategoryVC, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension StatisticsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.topCategoryStats.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CategoryStatCell.reuseIdentifier, for: indexPath) as? CategoryStatCell else {
            return UITableViewCell()
        }

        let stat = viewModel.topCategoryStats[indexPath.row]
        cell.configure(with: stat)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension StatisticsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

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
