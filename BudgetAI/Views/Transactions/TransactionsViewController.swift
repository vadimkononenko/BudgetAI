//
//  TransactionsViewController.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import UIKit
import SnapKit
import CoreData

final class TransactionsViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: TransactionsViewModel
    private let coreDataManager = CoreDataManager.shared
    private var transactions: [Transaction] = []
    private var fetchedResultsController: NSFetchedResultsController<Transaction>!
    private var selectedCategory: Category?
    private var allCategories: [Category] = []

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
        loadCategories()
        setupFetchedResultsController()
        fetchTransactions()
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

    private func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: coreDataManager.context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        fetchedResultsController.delegate = self
    }

    private func loadCategories() {
        switch coreDataManager.fetch(Category.self) {
        case .success(let categories):
            allCategories = categories
        case .failure(let error):
            print("Failed to load categories: \(error)")
            allCategories = []
        }
        updateFilterMenu()
    }

    private func updateFilterMenu() {
        var menuActions: [UIAction] = []
        
        let filteredCategories: [Category]
        let selectedSegment = segmentedControl.selectedSegmentIndex
        
        if selectedSegment == 1 {
            filteredCategories = allCategories.filter { $0.type == "expense" }
        } else if selectedSegment == 2 {
            filteredCategories = allCategories.filter { $0.type == "income" }
        } else {
            filteredCategories = allCategories
        }

        let allAction = UIAction(
            title: "Всі категорії",
            image: selectedCategory == nil ? UIImage(systemName: "checkmark") : nil
        ) { [weak self] _ in
            self?.selectedCategory = nil
            self?.updateFilterBarButtonItem()
            self?.fetchTransactions()
        }
        menuActions.append(allAction)

        for category in filteredCategories {
            let isSelected = selectedCategory?.id == category.id
            let title = "\(category.icon ?? "") \(category.name ?? "")"
            let action = UIAction(
                title: title,
                image: isSelected ? UIImage(systemName: "checkmark") : nil
            ) { [weak self] _ in
                self?.selectedCategory = category
                self?.updateFilterBarButtonItem()
                self?.fetchTransactions()
            }
            menuActions.append(action)
        }
        
        navigationItem.leftBarButtonItem?.menu = UIMenu(children: menuActions)
    }

    private func updateFilterBarButtonItem() {
        guard let filterItem = navigationItem.leftBarButtonItem else { return }

        if let category = selectedCategory {
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

    private func fetchTransactions() {
        let selectedSegment = segmentedControl.selectedSegmentIndex
        var predicates: [NSPredicate] = []

        if selectedSegment == 1 {
            predicates.append(NSPredicate(format: "type == %@", "expense"))
        } else if selectedSegment == 2 {
            predicates.append(NSPredicate(format: "type == %@", "income"))
        }

        if let category = selectedCategory {
            predicates.append(NSPredicate(format: "category == %@", category))
        }

        if predicates.isEmpty {
            fetchedResultsController.fetchRequest.predicate = nil
        } else if predicates.count == 1 {
            fetchedResultsController.fetchRequest.predicate = predicates.first
        } else {
            fetchedResultsController.fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        do {
            try fetchedResultsController.performFetch()
            transactions = fetchedResultsController.fetchedObjects ?? []
            tableView.reloadData()
            updateEmptyState()
        } catch {
            print("Failed to fetch transactions: \(error)")
        }
    }

    private func updateEmptyState() {
        emptyStateLabel.isHidden = !transactions.isEmpty
    }

    // MARK: - Actions

    @objc private func addButtonTapped() {
        let addVC = AddTransactionViewController()
        let navController = UINavigationController(rootViewController: addVC)
        present(navController, animated: true)
    }

    @objc private func segmentChanged() {
        let selectedType: String?
        switch segmentedControl.selectedSegmentIndex {
        case 1: selectedType = "expense"
        case 2: selectedType = "income"
        default: selectedType = nil
        }

        if let category = selectedCategory, let type = selectedType, category.type != type {
            selectedCategory = nil
        }

        updateFilterBarButtonItem()

        fetchTransactions()
    }
}

// MARK: - UITableViewDataSource

extension TransactionsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TransactionCell.reuseIdentifier, for: indexPath) as? TransactionCell else {
            return UITableViewCell()
        }

        let transaction = transactions[indexPath.row]
        cell.configure(with: transaction)
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
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Видалити") { [weak self] _, _, completion in
            guard let self = self else { return }
            let transaction = self.transactions[indexPath.row]

            let result = self.coreDataManager.delete(transaction)
            switch result {
            case .success:
                NotificationCenter.default.post(name: .transactionDidDelete, object: nil)
                completion(true)
            case .failure(let error):
                ErrorPresenter.show(error, in: self)
                completion(false)
            }
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension TransactionsViewController: NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        transactions = fetchedResultsController.fetchedObjects ?? []
        tableView.reloadData()
        updateEmptyState()
    }
}
