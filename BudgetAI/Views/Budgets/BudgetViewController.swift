//
//  BudgetViewController.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import UIKit
import SnapKit

final class BudgetViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: BudgetViewModel

    // MARK: - UI Components
    
    private lazy var addBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .systemBackground
        tableView.register(BudgetCell.self, forCellReuseIdentifier: BudgetCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    private lazy var previousMonthButton = makeNavigationButton(image: "chevron.left", action: #selector(previousMonthTapped))

    private lazy var monthYearLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        return label
    }()

    private lazy var nextMonthButton = makeNavigationButton(image: "chevron.right", action: #selector(nextMonthTapped))

    private lazy var archiveLabel: UILabel = {
        let label = UILabel()
        label.text = "📦 Архів"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "Немає бюджетів\nДодайте новий бюджет, натиснувши «+»"
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    // MARK: - Initialization

    init(viewModel: BudgetViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        // For Storyboard compatibility (not used)
        self.viewModel = DIContainer.shared.makeBudgetViewModel()
        super.init(coder: coder)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupNotifications()
        viewModel.fetchBudgets()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchBudgets()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func makeNavigationButton(image: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: image), for: .normal)
        button.tintColor = .label
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func setupUI() {
        title = "Бюджети"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = addBarButtonItem

        view.addSubview(previousMonthButton)
        view.addSubview(monthYearLabel)
        view.addSubview(nextMonthButton)
        view.addSubview(archiveLabel)
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)

        previousMonthButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalTo(monthYearLabel)
            make.width.height.equalTo(32)
        }

        monthYearLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.centerX.equalToSuperview()
        }

        nextMonthButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(monthYearLabel)
            make.width.height.equalTo(32)
        }

        archiveLabel.snp.makeConstraints { make in
            make.top.equalTo(monthYearLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(archiveLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }

        emptyStateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
    }

    private func setupBindings() {
        viewModel.onBudgetsUpdated = { [weak self] in
            self?.updateUI()
        }

        viewModel.onError = { [weak self] error in
            guard let self = self else { return }
            ErrorPresenter.show(error, in: self)
        }

        updateUI()
    }

    private func updateUI() {
        monthYearLabel.text = viewModel.getMonthYearString()

        previousMonthButton.isEnabled = viewModel.canNavigateToPreviousMonth()
        previousMonthButton.alpha = previousMonthButton.isEnabled ? 1.0 : 0.3

        nextMonthButton.isEnabled = viewModel.canNavigateToNextMonth()
        nextMonthButton.alpha = nextMonthButton.isEnabled ? 1.0 : 0.3

        navigationItem.rightBarButtonItem = viewModel.shouldShowAddButton ? addBarButtonItem : nil
        archiveLabel.isHidden = !viewModel.shouldShowArchiveLabel

        emptyStateLabel.text = viewModel.emptyStateText
        emptyStateLabel.isHidden = !viewModel.isEmpty

        tableView.reloadData()
    }

    private func setupNotifications() {
        [Notification.Name.transactionDidAdd, .transactionDidDelete].forEach { notification in
            NotificationCenter.default.addObserver(self, selector: #selector(handleTransactionChanged), name: notification, object: nil)
        }
    }


    // MARK: - Actions

    @objc private func addButtonTapped() {
        let addBudgetVC = AddBudgetViewController()
        addBudgetVC.delegate = self

        if let sheet = addBudgetVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }

        present(addBudgetVC, animated: true)
    }

    @objc private func handleTransactionChanged() {
        // Opening only if current month is on users view
        if viewModel.isCurrentMonth {
            viewModel.fetchBudgets()
        }
    }

    @objc private func previousMonthTapped() {
        viewModel.navigateToPreviousMonth()
    }

    @objc private func nextMonthTapped() {
        viewModel.navigateToNextMonth()
    }
}

// MARK: - UITableViewDataSource

extension BudgetViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.budgets.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BudgetCell.reuseIdentifier, for: indexPath) as? BudgetCell else {
            return UITableViewCell()
        }

        let budgetDisplayModel = viewModel.budgets[indexPath.row]
        cell.configure(with: budgetDisplayModel)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension BudgetViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if let budget = viewModel.getBudget(at: indexPath.row) {
            let detailVC = BudgetDetailViewController(budget: budget, month: viewModel.selectedMonth, year: viewModel.selectedYear)
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard viewModel.isCurrentMonth else {
            return nil
        }

        let deleteAction = UIContextualAction(style: .destructive, title: "Видалити") { [weak self] _, _, completion in
            guard let self = self else { return }
            self.viewModel.deleteBudget(at: indexPath.row)
            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - AddBudgetDelegate

extension BudgetViewController: AddBudgetDelegate {

    func didAddBudget() {
        viewModel.fetchBudgets()
    }
}
