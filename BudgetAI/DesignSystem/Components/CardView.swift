//
//  CardView.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 21.10.2025.
//

import UIKit

final class CardView: UIView {

    // MARK: - Initialization

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
    }
}
