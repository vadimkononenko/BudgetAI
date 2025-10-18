//
//  CategorySelectionViewController.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import UIKit
import SnapKit

protocol CategorySelectionDelegate: AnyObject {
    func didSelectCategory(_ category: Category)
}

final class CategorySelectionViewController: UIViewController {

    // MARK: - Properties

    private let coreDataManager = CoreDataManager.shared
    private var categories: [Category] = []
    private let transactionType: String
    weak var delegate: CategorySelectionDelegate?

    // MARK: - UI Components

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.reuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()

    // MARK: - Initialization

    init(transactionType: String) {
        self.transactionType = transactionType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchCategories()
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Виберіть категорію"
        view.backgroundColor = .systemBackground

        view.addSubview(collectionView)

        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func fetchCategories() {
        let predicate = NSPredicate(format: "type == %@", transactionType)
        let result = coreDataManager.fetch(Category.self, predicate: predicate)
        
        switch result {
        case .success(let fetchedCategories):
            categories = fetchedCategories
            collectionView.reloadData()
        case .failure(let error):
            print("Failed to fetch categories: \(error)")
            categories = []
            collectionView.reloadData()
        }
    }
}

// MARK: - UICollectionViewDataSource

extension CategorySelectionViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCell.reuseIdentifier, for: indexPath) as? CategoryCell else {
            return UICollectionViewCell()
        }

        let category = categories[indexPath.item]
        cell.configure(with: category)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension CategorySelectionViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let category = categories[indexPath.item]
        delegate?.didSelectCategory(category)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension CategorySelectionViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 16
        let numberOfColumns: CGFloat = 3
        let totalPadding = padding * (numberOfColumns + 1)
        let itemWidth = (collectionView.bounds.width - totalPadding) / numberOfColumns
        return CGSize(width: itemWidth, height: itemWidth)
    }
}

// MARK: - CategoryCell

final class CategoryCell: UICollectionViewCell {

    static let reuseIdentifier = "CategoryCell"

    // MARK: - UI Components

    private lazy var iconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 40)
        label.textAlignment = .center
        return label
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        return view
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(iconLabel)
        containerView.addSubview(nameLabel)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-10)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(iconLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(4)
        }
    }

    // MARK: - Configuration

    func configure(with category: Category) {
        iconLabel.text = category.icon
        nameLabel.text = category.name

        if let colorHex = category.colorHex {
            containerView.backgroundColor = UIColor(hex: colorHex)?.withAlphaComponent(0.3) ?? .secondarySystemBackground
        }
    }
}
