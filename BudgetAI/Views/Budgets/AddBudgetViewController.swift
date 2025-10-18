//
//  AddBudgetViewController.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import UIKit
import SnapKit

protocol AddBudgetDelegate: AnyObject {
    func didAddBudget()
}

final class AddBudgetViewController: UIViewController {

    // MARK: - Properties

    private let coreDataManager = CoreDataManager.shared
    private var expenseCategories: [Category] = []
    private var selectedCategory: Category?
    private var currentMonth: Int16 = 0
    private var currentYear: Int16 = 0
    weak var delegate: AddBudgetDelegate?

    // MARK: - UI Components

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Новий бюджет"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private lazy var amountTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Введіть суму"
        textField.font = .systemFont(ofSize: 18, weight: .medium)
        textField.keyboardType = .decimalPad
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .secondarySystemBackground
        textField.delegate = self
        return textField
    }()

    private lazy var categoryLabel: UILabel = {
        let label = UILabel()
        label.text = "Категорія"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }()

    private lazy var categoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Виберіть категорію", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .secondarySystemBackground
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 8
        button.contentHorizontalAlignment = .left
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
        button.addTarget(self, action: #selector(categoryButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var chevronImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.down"))
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var selectedCategoryIconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20)
        label.textAlignment = .center
        return label
    }()

    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Зберегти", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Скасувати", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCurrentMonthYear()
        fetchCategories()
        setupCategoryMenu()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(titleLabel)
        view.addSubview(amountTextField)
        view.addSubview(categoryLabel)
        view.addSubview(categoryButton)
        categoryButton.addSubview(chevronImageView)
        categoryButton.addSubview(selectedCategoryIconLabel)
        view.addSubview(saveButton)
        view.addSubview(cancelButton)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        amountTextField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(48)
        }

        categoryLabel.snp.makeConstraints { make in
            make.top.equalTo(amountTextField.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
        }

        categoryButton.snp.makeConstraints { make in
            make.top.equalTo(categoryLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(48)
        }

        selectedCategoryIconLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
        }

        chevronImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }

        saveButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(cancelButton.snp.top).offset(-12)
            make.height.equalTo(56)
        }

        cancelButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.height.equalTo(44)
        }
    }

    private func setupCurrentMonthYear() {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: Date())
        currentMonth = Int16(components.month ?? 1)
        currentYear = Int16(components.year ?? 2025)
    }

    private func fetchCategories() {
        let predicate = NSPredicate(format: "type == %@", "expense")
        let result = coreDataManager.fetch(Category.self, predicate: predicate)
        
        switch result {
        case .success(let categories):
            expenseCategories = categories
        case .failure(let error):
            print("Failed to fetch categories: \(error)")
            expenseCategories = []
        }
    }

    private func setupCategoryMenu() {
        var menuActions: [UIAction] = []

        for category in expenseCategories {
            let action = UIAction(title: category.name ?? "", image: nil) { [weak self] _ in
                self?.didSelectCategory(category)
            }
            menuActions.append(action)
        }

        let menu = UIMenu(title: "", children: menuActions)
        categoryButton.menu = menu
        categoryButton.showsMenuAsPrimaryAction = true
    }

    private func didSelectCategory(_ category: Category) {
        selectedCategory = category
        categoryButton.setTitle(category.name, for: .normal)
        selectedCategoryIconLabel.text = category.icon
    }

    // MARK: - Actions

    @objc private func categoryButtonTapped() {
        
    }

    @objc private func saveButtonTapped() {
        guard let amountText = amountTextField.text,
              let amount = Double(amountText),
              amount > 0 else {
            showAlert(title: "Помилка", message: "Будь ласка, введіть суму")
            return
        }

        guard let category = selectedCategory else {
            showAlert(title: "Помилка", message: "Будь ласка, виберіть категорію")
            return
        }

        let budget = coreDataManager.create(Budget.self)
        budget.id = UUID()
        budget.amount = amount
        budget.month = currentMonth
        budget.year = currentYear
        budget.isActive = true
        budget.category = category

        let result = coreDataManager.saveContext()
        switch result {
        case .success:
            delegate?.didAddBudget()
            dismiss(animated: true)
        case .failure(let error):
            showAlert(title: "Помилка", message: "Не вдалося зберегти бюджет: \(error.localizedDescription)")
        }
    }

    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension AddBudgetViewController: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let allowedCharacters = CharacterSet(charactersIn: "0123456789.,")
        let characterSet = CharacterSet(charactersIn: string)
        return allowedCharacters.isSuperset(of: characterSet)
    }
}
