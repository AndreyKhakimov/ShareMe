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
    private let historicalDataNetworkManager = HistoricalDataNetworkManager()
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    // Added simple chart for testing
    private let simpleChart: SimpleChartView = {
        let simpleChart =  SimpleChartView()
        simpleChart.lineColor = .green
        simpleChart.gradientColor = .green.withAlphaComponent(0.5)
        return simpleChart
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        fetchPrice(for: code ?? "", and: exchange ?? "")
        fetchHistoricalData(assetName: code ?? "", exchange: exchange ?? "")
    }
    
    private func setupViews() {
        view.backgroundColor = .white
        view.addSubview(descriptionLabel)
        view.addSubview(simpleChart)
        
        descriptionLabel.snp.makeConstraints { make in
            make.width.equalTo(200)
            make.center.equalToSuperview()
        }
        // Added simple chart constraints for testing
        simpleChart.snp.makeConstraints { make in
            make.width.height.equalTo(200)
            make.centerX.equalToSuperview()
            make.top.equalTo(descriptionLabel.snp.bottom).offset(16)
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
    
    private func fetchHistoricalData(assetName: String, exchange: String, from: String = Date().getPreviousMonthDate().shortFormatString, to: String = Date().shortFormatString, period: Period = .day) {
        historicalDataNetworkManager.getHistoricalData(
            assetName: assetName,
            exchange: exchange,
            from: from,
            to: to,
            period: period) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    switch result {
                    case .success(let data):
                        let closePrices = data.map { $0.close }
                        self.simpleChart.chartData = closePrices
                    case .failure(let error):
                        self.showAlert(title: error.title, message: error.description)
                    }
                }
            }
    }
    
}
