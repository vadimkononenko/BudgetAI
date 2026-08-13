//
//  TransactionsViewController.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import UIKit
import SnapKit

final class TransactionsViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: TransactionsViewModel

    // MARK: - UI Components

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.register(TransactionCell.self, forCellReuseIdentifier: TransactionCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    private lazy var segmentedControl: UISegmentedControl = {
        let items = ["Всі", "Витрати", "Доходи"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        return control
    }()

    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "Немає транзакцій\nДодайте нову транзакцію, натиснувши +"
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    // MARK: - Initialization

    init(viewModel: TransactionsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        // For Storyboard compatibility (not used)
        self.viewModel = DIContainer.shared.makeTransactionsViewModel()
        super.init(coder: coder)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        setupBindings()
        viewModel.loadCategories()
        updateFilterMenu()
        viewModel.fetchTransactions()
    }

    // MARK: - Bindings

    private func setupBindings() {
        viewModel.onTransactionsUpdated = { [weak self] in
            self?.updateUI()
        }

        viewModel.onError = { [weak self] error in
            guard let self = self else { return }
            ErrorPresenter.show(error, in: self)
        }
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        title = "Транзакції"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.tintColor = .black

        let addButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )
        navigationItem.rightBarButtonItem = addButtonItem

        let filterButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
            style: .plain,
            target: self,
            action: nil
        )
        navigationItem.leftBarButtonItem = filterButtonItem
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(segmentedControl)
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)

        segmentedControl.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview()
        }

        emptyStateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
    }


    private func updateFilterMenu() {
        let menuItems = viewModel.getFilterMenuItems()
        let menuActions = menuItems.map { item in
            createFilterAction(for: item)
        }
        navigationItem.leftBarButtonItem?.menu = UIMenu(children: menuActions)
    }

    private func createFilterAction(for item: TransactionsViewModel.FilterMenuItem) -> UIAction {
        return UIAction(
            title: item.title,
            image: item.isSelected ? UIImage(systemName: "checkmark") : nil
        ) { [weak self] _ in
            self?.viewModel.setCategory(item.category)
            self?.updateFilterBarButtonItem()
        }
    }

    private func updateFilterBarButtonItem() {
        guard let filterItem = navigationItem.leftBarButtonItem else { return }

        if viewModel.hasSelectedCategory(), let category = viewModel.selectedCategory {
            filterItem.title = category.name
            filterItem.image = nil
            filterItem.tintColor = .systemOrange
        } else {
            filterItem.title = nil
            filterItem.image = UIImage(systemName: "line.3.horizontal.decrease.circle")
            filterItem.tintColor = .black
        }
        updateFilterMenu()
    }

    private func updateUI() {
        tableView.reloadData()
        updateEmptyState()
    }

    private func updateEmptyState() {
        emptyStateLabel.isHidden = !viewModel.isEmpty()
    }

    // MARK: - Actions

    @objc private func addButtonTapped() {
        let addVC = AddTransactionViewController()
        let navController = UINavigationController(rootViewController: addVC)
        present(navController, animated: true)
    }

    @objc private func segmentChanged() {
        let filterType: TransactionsViewModel.FilterType
        switch segmentedControl.selectedSegmentIndex {
        case 1: filterType = .expenses
        case 2: filterType = .income
        default: filterType = .all
        }

        viewModel.setFilter(filterType)
        updateFilterBarButtonItem()
    }
}

// MARK: - UITableViewDataSource

extension TransactionsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.transactions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TransactionCell.reuseIdentifier, for: indexPath) as? TransactionCell else {
            return UITableViewCell()
        }

        let displayModel = viewModel.transactions[indexPath.row]
        cell.configure(with: displayModel)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension TransactionsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let transaction = viewModel.getTransaction(at: indexPath.row) else { return }
        let detailVC = TransactionDetailViewController(transaction: transaction)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Видалити") { [weak self] _, _, completion in
            guard let self = self else { return }
            self.viewModel.deleteTransaction(at: indexPath.row)
            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

