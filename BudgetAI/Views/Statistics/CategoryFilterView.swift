//
//  CategoryFilterView.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 25.10.2025.
//

import UIKit
import SnapKit

/// A view that displays category filter chips for filtering statistics by categories
final class CategoryFilterView: UIView {

    // MARK: - Properties

    /// Array of category statistics to display as filter options
    private var categories: [CategoryStatDisplayModel] = []

    /// Set of currently selected category names
    private var selectedCategories: Set<String> = []

    /// Callback closure invoked when filter selection changes
    /// - Parameter selectedCategories: Array of selected category names
    var onFilterChanged: (([String]) -> Void)?

    // MARK: - UI Components

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.Statistics.filterByCategories
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private lazy var clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(L10n.Statistics.clear, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CategoryFilterCell.self, forCellWithReuseIdentifier: CategoryFilterCell.reuseIdentifier)
        return collectionView
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12

        addSubview(titleLabel)
        addSubview(clearButton)
        addSubview(collectionView)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(16)
        }

        clearButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-16)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-12)
            make.height.equalTo(40)
        }
    }

    // MARK: - Public Methods

    /// Configures the filter view with categories and selected state
    /// - Parameters:
    ///   - categories: Array of category statistics to display
    ///   - selectedCategories: Set of currently selected category names
    func configure(categories: [CategoryStatDisplayModel], selectedCategories: Set<String>) {
        self.categories = categories
        self.selectedCategories = selectedCategories
        collectionView.reloadData()
    }

    // MARK: - Actions

    @objc private func clearButtonTapped() {
        selectedCategories.removeAll()
        collectionView.reloadData()
        onFilterChanged?(Array(selectedCategories))
    }
}

// MARK: - UICollectionViewDataSource

extension CategoryFilterView: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryFilterCell.reuseIdentifier, for: indexPath) as? CategoryFilterCell else {
            return UICollectionViewCell()
        }

        let category = categories[indexPath.item]
        let isSelected = selectedCategories.isEmpty || selectedCategories.contains(category.categoryName)
        cell.configure(with: category, isSelected: isSelected)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension CategoryFilterView: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let category = categories[indexPath.item]

        if selectedCategories.contains(category.categoryName) {
            selectedCategories.remove(category.categoryName)
        } else {
            selectedCategories.insert(category.categoryName)
        }

        collectionView.reloadData()
        onFilterChanged?(Array(selectedCategories))
    }
}

// MARK: - CategoryFilterCell

/// A collection view cell that displays a category filter chip
final class CategoryFilterCell: UICollectionViewCell {

    /// Reuse identifier for cell registration
    static let reuseIdentifier = "CategoryFilterCell"

    // MARK: - UI Components

    private lazy var containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 1.5
        return view
    }()

    private lazy var iconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        return label
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [iconLabel, nameLabel])
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        return stack
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(stackView)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        stackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8)
            make.leading.trailing.equalToSuperview().inset(12)
        }
    }

    // MARK: - Configuration

    /// Configures the cell with category data and selection state
    /// - Parameters:
    ///   - category: The category statistics model to display
    ///   - isSelected: Whether the category is currently selected
    func configure(with category: CategoryStatDisplayModel, isSelected: Bool) {
        iconLabel.text = category.categoryIcon
        nameLabel.text = category.categoryName

        if isSelected {
            containerView.backgroundColor = category.categoryColor.withAlphaComponent(0.2)
            containerView.layer.borderColor = category.categoryColor.cgColor
            nameLabel.textColor = .label
        } else {
            containerView.backgroundColor = .tertiarySystemBackground
            containerView.layer.borderColor = UIColor.separator.cgColor
            nameLabel.textColor = .secondaryLabel
        }
    }
}
