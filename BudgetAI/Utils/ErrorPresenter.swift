//
//  ErrorPresenter.swift
//  BudgetAI
//
//  Created by Vadim Kononenko on 16.10.2025.
//

import UIKit

// MARK: - ErrorPresenter

final class ErrorPresenter {

    // MARK: - Alert Presentation

    static func show(_ error: Error, in viewController: UIViewController, retryAction: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            let title = "Помилка"
            let message = error.localizedDescription

            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

            if let retryAction = retryAction {
                alert.addAction(UIAlertAction(title: "Повторити", style: .default) { _ in
                    retryAction()
                })
                alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
            } else {
                alert.addAction(UIAlertAction(title: "OK", style: .default))
            }

            viewController.present(alert, animated: true)
        }
    }

    static func showCriticalError(_ error: Error, in viewController: UIViewController) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Критична помилка",
                message: error.localizedDescription,
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "OK", style: .destructive))
            viewController.present(alert, animated: true)
        }
    }

    // MARK: - Toast Presentation

    static func showToast(_ message: String, in view: UIView, duration: TimeInterval = 3.0) {
        DispatchQueue.main.async {
            let toastLabel = UILabel()
            toastLabel.text = message
            toastLabel.font = .systemFont(ofSize: 14, weight: .medium)
            toastLabel.textColor = .white
            toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
            toastLabel.textAlignment = .center
            toastLabel.numberOfLines = 0
            toastLabel.layer.cornerRadius = 10
            toastLabel.clipsToBounds = true
            toastLabel.alpha = 0

            view.addSubview(toastLabel)
            toastLabel.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                toastLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
                toastLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
                toastLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                toastLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
            ])

            UIView.animate(withDuration: 0.3, animations: {
                toastLabel.alpha = 1.0
            }, completion: { _ in
                UIView.animate(withDuration: 0.3, delay: duration, options: [], animations: {
                    toastLabel.alpha = 0.0
                }, completion: { _ in
                    toastLabel.removeFromSuperview()
                })
            })
        }
    }

    static func showSuccessToast(_ message: String, in view: UIView) {
        showToast(message, in: view)
    }

    static func showErrorToast(_ error: Error, in view: UIView) {
        showToast(error.localizedDescription, in: view)
    }
}
