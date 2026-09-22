//
//  LaunchFailureViewController.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 20.08.2026.
//

import UIKit
import SnapKit

class LaunchFailureViewController: UIViewController {

    // MARK: - Private Properties

    private let error: Error
    private let onRetry: () -> Void

    private var userFacingMessage: String {
        let description = (error as? LocalizedError)?.errorDescription ?? "Сталася невідома помилка"
        let suggestion = (error as? LocalizedError)?.recoverySuggestion

        return [description, suggestion]
            .compactMap { $0 }
            .joined(separator: "\n\n")
    }

    // MARK: - Views

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Не вдалося запустити застосунок"
        label.font = .preferredFont(forTextStyle: .title2)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.text = userFacingMessage
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Спробувати ще раз", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        return button
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, messageLabel, retryButton])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        return stackView
    }()

    // MARK: - Init

    init(
        error: Error,
        onRetry: @escaping () -> Void
    ) {
        self.error = error
        self.onRetry = onRetry
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Actions

    @objc private func retryTapped() {
        onRetry()
    }
}

// MARK: - UI Setup

private extension LaunchFailureViewController {
    func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.center.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(32)
        }
    }
}
