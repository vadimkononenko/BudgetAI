//
//  TransactionFormBuilder.swift
//  BudgetAI
//
//  Created by Vadim Kononenko
//

import UIKit
import SnapKit

/// A builder class responsible for creating and configuring UI components for the transaction form
/// This class encapsulates all UI component creation logic, providing a clean separation of concerns
/// and making the form components reusable across different views if needed
final class TransactionFormBuilder {

    // MARK: - Scroll View Components

    /// Creates a scroll view with interactive keyboard dismiss mode
    /// - Returns: A configured UIScrollView for the transaction form
    static func createScrollView() -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.keyboardDismissMode = .interactive
        return scrollView
    }

    /// Creates a content view to hold all form elements inside the scroll view
    /// - Returns: A configured UIView
    static func createContentView() -> UIView {
        let view = UIView()
        return view
    }

    // MARK: - Type Selection

    /// Creates a segmented control for selecting transaction type (expense/income)
    /// - Parameters:
    ///   - target: The target object for the value changed action
    ///   - action: The selector to call when the value changes
    /// - Returns: A configured UISegmentedControl with expense and income options
    static func createTypeSegmentedControl(target: Any?, action: Selector) -> UISegmentedControl {
        let items = ["Expense", "Income"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.addTarget(target, action: action, for: .valueChanged)
        return control
    }

    // MARK: - Amount Input

    /// Creates a text field for entering transaction amount
    /// - Parameter delegate: The UITextFieldDelegate to handle text field events
    /// - Returns: A configured UITextField with decimal pad keyboard and large bold font
    static func createAmountTextField(delegate: UITextFieldDelegate?) -> UITextField {
        let textField = UITextField()
        textField.placeholder = "Amount"
        textField.font = .systemFont(ofSize: 32, weight: .bold)
        textField.textAlignment = .center
        textField.keyboardType = .decimalPad
        textField.delegate = delegate
        return textField
    }

    /// Creates a currency label to display next to the amount field
    /// - Parameter currencySymbol: The currency symbol to display (default: "₴")
    /// - Returns: A configured UILabel with large bold font and secondary color
    static func createCurrencyLabel(currencySymbol: String = "₴") -> UILabel {
        let label = UILabel()
        label.text = currencySymbol
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .secondaryLabel
        return label
    }

    // MARK: - Category Selection

    /// Creates a button for category selection with a dropdown menu
    /// - Returns: A configured UIButton with rounded corners and menu support
    static func createCategoryButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(L10n.Transaction.selectCategory, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .secondarySystemBackground
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 12
        button.contentHorizontalAlignment = .left
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        button.showsMenuAsPrimaryAction = true
        return button
    }

    /// Creates a label to display the category icon inside the category button
    /// - Returns: A configured UILabel for emoji/icon display
    static func createCategoryIconLabel() -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24)
        label.textAlignment = .center
        return label
    }

    // MARK: - Description Input

    /// Creates a text view for entering transaction description
    /// - Parameter delegate: The UITextViewDelegate to handle text view events
    /// - Returns: A configured UITextView with rounded corners and padding
    static func createDescriptionTextView(delegate: UITextViewDelegate?) -> UITextView {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16, weight: .regular)
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 12
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.delegate = delegate
        return textView
    }

    /// Creates a placeholder label for the description text view
    /// - Returns: A configured UILabel with placeholder styling
    static func createDescriptionPlaceholder() -> UILabel {
        let label = UILabel()
        label.text = L10n.Transaction.descriptionOptional
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .placeholderText
        return label
    }

    // MARK: - Date Selection

    /// Creates a label for the date picker
    /// - Returns: A configured UILabel with "Date:" text
    static func createDateLabel() -> UILabel {
        let label = UILabel()
        label.text = L10n.Transaction.date
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }

    /// Creates a date picker for selecting transaction date and time
    /// - Returns: A configured UIDatePicker with compact style and maximum date set to now
    static func createDatePicker() -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .compact
        picker.maximumDate = Date()
        return picker
    }

    // MARK: - Action Button

    /// Creates a save button for submitting the transaction form
    /// - Parameters:
    ///   - target: The target object for the touch up inside action
    ///   - action: The selector to call when the button is tapped
    /// - Returns: A configured UIButton with primary blue background
    static func createSaveButton(target: Any?, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(L10n.Transaction.save, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }

    // MARK: - Layout Setup

    /// Sets up constraints for all form components in the view hierarchy
    /// This method configures the complete layout using SnapKit constraints
    /// - Parameters:
    ///   - scrollView: The scroll view containing all form elements
    ///   - contentView: The content view inside the scroll view
    ///   - typeSegmentedControl: The transaction type segmented control
    ///   - amountTextField: The amount input text field
    ///   - currencyLabel: The currency symbol label
    ///   - categoryButton: The category selection button
    ///   - categoryIconLabel: The category icon label
    ///   - descriptionTextView: The description text view
    ///   - descriptionPlaceholder: The description placeholder label
    ///   - dateLabel: The date label
    ///   - datePicker: The date picker
    ///   - saveButton: The save button
    static func setupConstraints(
        scrollView: UIScrollView,
        contentView: UIView,
        typeSegmentedControl: UISegmentedControl,
        amountTextField: UITextField,
        currencyLabel: UILabel,
        categoryButton: UIButton,
        categoryIconLabel: UILabel,
        descriptionTextView: UITextView,
        descriptionPlaceholder: UILabel,
        dateLabel: UILabel,
        datePicker: UIDatePicker,
        saveButton: UIButton
    ) {
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
}
