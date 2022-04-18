//
//  AssetsViewController.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 10.04.2022.
//

import UIKit

class AssetsViewController: UIViewController {
    private let networkManager = PricesNetworkManager()
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
//        fetchPrice(for: "AAPL")
        fetchPrices(companySymbol: "AMZN", resolution: "D", from: 1648927048, to: 1650310996)
    }
    
    private func setupViews() {
        view.backgroundColor = .white
        view.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            descriptionLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 3/4),
            descriptionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 50)
        ])
    }
    
    private func fetchPrice(for companySymbol: String) {
        networkManager.getCompanyQuote(
            companySymbol: companySymbol) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    switch result {
                    case .success(let quotation):
                        self.descriptionLabel.text = quotation.description
                    case .failure(let error):
                        self.showAlert(title: error.title, message: error.description)
                    }
                }
            }
    }
    
    private func fetchPrices(companySymbol: String, resolution: String, from: Int, to: Int) {
        networkManager.getPrices(
            companySymbol: companySymbol,
            resolution: resolution,
            from: from,
            to: to) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    switch result {
                    case .success(let pricesList):
                        self.descriptionLabel.text = pricesList.description
                    case .failure(let error):
                        self.showAlert(title: error.title, message: error.description)
                    }
                }
            }
    }

}
