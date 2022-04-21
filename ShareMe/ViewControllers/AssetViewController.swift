//
//  AssetsViewController.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 10.04.2022.
//

import UIKit
import SnapKit

class AssetViewController: UIViewController {
    var code: String?
    var exchange: String?
    
    private let networkManager = QuoteNetworkManager()
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        fetchPrice(for: code ?? "", and: exchange ?? "")
    }
    
    private func setupViews() {
        view.backgroundColor = .white
        view.addSubview(descriptionLabel)
        // weak self
        descriptionLabel.snp.makeConstraints { make in
            make.width.equalTo(200)
            make.center.equalToSuperview()
        }
    
    }
    
    private func fetchPrice(for code: String, and exchange: String) {
        networkManager.getQuote(name: code, exchange: exchange) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    switch result {
                    case .success(let quote):
                        self.descriptionLabel.text = quote.description
                    case .failure(let error):
                        self.showAlert(title: error.title, message: error.description)
                    }
                }
            }
    }
    
//    private func fetchPrices(companySymbol: String, resolution: String, from: Int, to: Int) {
//        networkManager.getPrices(
//            companySymbol: companySymbol,
//            resolution: resolution,
//            from: from,
//            to: to) { [weak self] result in
//                DispatchQueue.main.async {
//                    guard let self = self else { return }
//
//                    switch result {
//                    case .success(let pricesList):
//                        self.descriptionLabel.text = pricesList.description
//                    case .failure(let error):
//                        self.showAlert(title: error.title, message: error.description)
//                    }
//                }
//            }
//    }

}
