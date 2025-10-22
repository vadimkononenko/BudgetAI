//
//  AddTransactionViewController.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import UIKit
import SnapKit

final class AddTransactionViewController: UIViewController {

    // MARK: - Properties

    private let coreDataManager = CoreDataManager.shared
    private let categorizationService = DIContainer.shared.categorizationService
    private var selectedCategory: Category?
    private var selectedType: String = "expense"
    private var categories: [Category] = []
    private var isCategoryAutoSelected = false
    private var categorizationTask: Task<Void, Never>?

    // MARK: - UI Components

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.keyboardDismissMode = .interactive
        return scrollView
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var typeSegmentedControl: UISegmentedControl = {
        let items = ["Витрата", "Дохід"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(typeChanged), for: .valueChanged)
        return control
    }()

    private lazy var amountTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Сума"
        textField.font = .systemFont(ofSize: 32, weight: .bold)
        textField.textAlignment = .center
        textField.keyboardType = .decimalPad
        textField.delegate = self
        return textField
    }()

    private lazy var currencyLabel: UILabel = {
        let label = UILabel()
        label.text = "₴"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var categoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Вибрати категорію", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .secondarySystemBackground
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 12
        button.contentHorizontalAlignment = .left
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        button.showsMenuAsPrimaryAction = true
        return button
    }()

    private lazy var categoryIconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24)
        label.textAlignment = .center
        return label
    }()

    private lazy var descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16, weight: .regular)
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 12
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.delegate = self
        return textView
    }()

    private lazy var descriptionPlaceholder: UILabel = {
        let label = UILabel()
        label.text = "Опис (опціонально)"
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .placeholderText
        return label
    }()

    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.text = "Дата:"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }()

    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .compact
        picker.maximumDate = Date()
        return picker
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

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadCategories()
        updateCategoryMenu()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(typeSegmentedControl)
        contentView.addSubview(amountTextField)
        contentView.addSubview(currencyLabel)
        contentView.addSubview(categoryButton)
        categoryButton.addSubview(categoryIconLabel)
        contentView.addSubview(descriptionTextView)
        descriptionTextView.addSubview(descriptionPlaceholder)
        contentView.addSubview(dateLabel)
        contentView.addSubview(datePicker)
        contentView.addSubview(saveButton)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        typeSegmentedControl.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        amountTextField.snp.makeConstraints { make in
            make.top.equalTo(typeSegmentedControl.snp.bottom).offset(32)
            make.centerX.equalToSuperview().offset(-20)
        }

        currencyLabel.snp.makeConstraints { make in
            make.leading.equalTo(amountTextField.snp.trailing).offset(8)
            make.centerY.equalTo(amountTextField)
        }

        categoryButton.snp.makeConstraints { make in
            make.top.equalTo(amountTextField.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(56)
        }

        categoryIconLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        descriptionTextView.snp.makeConstraints { make in
            make.top.equalTo(categoryButton.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(100)
        }

        descriptionPlaceholder.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(16)
        }

        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionTextView.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(16)
        }

        datePicker.snp.makeConstraints { make in
            make.centerY.equalTo(dateLabel)
            make.trailing.equalToSuperview().offset(-16)
        }

        saveButton.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(56)
            make.bottom.equalToSuperview().offset(-32)
        }
    }

    private func setupNavigationBar() {
        title = "Нова транзакція"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelButtonTapped)
        )
    }

    private func loadCategories() {
        switch coreDataManager.fetch(Category.self) {
        case .success(let allCategories):
            categories = allCategories.filter { $0.type == selectedType }
        case .failure(let error):
            categories = []
            print("Failed to load categories: \(error.localizedDescription)")
        }
    }

    private func updateCategoryMenu() {
        var menuActions: [UIAction] = []

        for category in categories {
            let title = "\(category.icon ?? "") \(category.name ?? "")"
            let action = UIAction(title: title) { [weak self] _ in
                self?.didSelectCategory(category)
            }
            menuActions.append(action)
        }

        categoryButton.menu = UIMenu(children: menuActions)
    }

    private func didSelectCategory(_ category: Category) {
        selectedCategory = category
        isCategoryAutoSelected = false // Скидаємо прапорець при ручному виборі
        categoryButton.setTitle(category.name, for: .normal)
        categoryIconLabel.text = category.icon
    }

    // MARK: - Actions

    @objc private func typeChanged() {
        selectedType = typeSegmentedControl.selectedSegmentIndex == 0 ? "expense" : "income"
        selectedCategory = nil
        isCategoryAutoSelected = false // Скидаємо прапорець при зміні типу
        categoryButton.setTitle("Вибрати категорію", for: .normal)
        categoryIconLabel.text = nil
        loadCategories()
        updateCategoryMenu()

        // Спробуємо передбачити категорію знову, якщо є опис
        if !descriptionTextView.text.isEmpty {
            scheduleCategoryPrediction(delay: 0.3)
        }
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

        let transaction = coreDataManager.create(Transaction.self)
        transaction.id = UUID()
        transaction.amount = amount
        transaction.type = selectedType
        transaction.date = datePicker.date
        transaction.createdAt = Date()
        transaction.transactionDescription = descriptionTextView.text.isEmpty ? nil : descriptionTextView.text
        transaction.category = category

        switch coreDataManager.saveContext() {
        case .success:
            NotificationCenter.default.post(name: .transactionDidAdd, object: nil)
            dismiss(animated: true)
        case .failure(let error):
            showAlert(title: "Помилка", message: "Не вдалося зберегти транзакцію: \(error.localizedDescription)")
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

extension AddTransactionViewController: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let allowedCharacters = CharacterSet(charactersIn: "0123456789.,")
        let characterSet = CharacterSet(charactersIn: string)
        return allowedCharacters.isSuperset(of: characterSet)
    }
}

// MARK: - UITextViewDelegate

extension AddTransactionViewController: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        descriptionPlaceholder.isHidden = !textView.text.isEmpty

        guard !textView.text.isEmpty else {
            categorizationTask?.cancel()
            return
        }

        guard textView.text.count >= 3 else {
            return
        }

        guard categorizationService != nil else {
            return
        }

        scheduleCategoryPrediction(delay: 0.5)
    }

    private func scheduleCategoryPrediction(delay: TimeInterval) {
        categorizationTask?.cancel()

        categorizationTask = Task {
            do {
                try await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { return }
                predictCategory()
            } catch { }
        }
    }

    @MainActor
    private func predictCategory() {
        guard let description = descriptionTextView.text, !description.isEmpty else {
            return
        }

        guard let service = categorizationService else {
            return
        }

        guard let predictedCategoryName = service.predictCategory(for: description, type: selectedType) else {
            return
        }

        guard let category = categories.first(where: { $0.name == predictedCategoryName }) else {
            return
        }

        guard selectedCategory == nil || isCategoryAutoSelected else {
            return
        }

        selectedCategory = category
        isCategoryAutoSelected = true

        UIView.animate(withDuration: 0.3) {
            self.categoryButton.setTitle("🤖 \(category.name ?? "")", for: .normal)
            self.categoryIconLabel.text = category.icon
        }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
