//
//  AssetsViewController.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 10.04.2022.
//

import UIKit
import SnapKit
import Charts
import Kingfisher

class AssetViewController: UIViewController {
    var code: String?
    var assetName: String?
    var exchange: String?
    var currency: String?
    var logoURL: URL?
    var quote: Quote?
    
    private let networkManager = QuoteNetworkManager()
    private let historicalDataNetworkManager = HistoricalDataNetworkManager()
    
    private lazy var assetInfoView: AssetInfoView = {
        let assetInfoView = AssetInfoView()
        return assetInfoView
    }()
    
    private lazy var mainChart: MainChartView = {
        let mainChart =  MainChartView()
        
        mainChart.xAxis.enabled = false
        mainChart.rightAxis.enabled = false
        mainChart.leftAxis.enabled = false
        
        return mainChart
    }()
    
    private lazy var chartSegmentedControl: CustomSegmentedControl = {
        let items = ["W" ,"M", "6M", "1Y", "All"]
        let segmentedControl = CustomSegmentedControl()
        segmentedControl.items = items
        segmentedControl.selectedSegmentIndex = 2
        segmentedControl.addTarget(self, action: #selector(timeIntervalDidChange(_:)), for: .valueChanged)
        return segmentedControl
    }()
    
    private lazy var barButtonView: BarButtonView = {
        let barButtonView = BarButtonView()
        barButtonView.logoImageView.kf.setImage(with: logoURL)
        barButtonView.descriptionLabel.text = assetName
        return barButtonView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        fetchPrice(for: code ?? "", and: exchange ?? "")
        fetchHistoricalData(assetName: code ?? "", exchange: exchange ?? "")
        mainChart.delegate = self
        configureLeftBarButton()
    }
    
    private func setupViews() {
        view.backgroundColor = .white
        view.addSubview(assetInfoView)
        view.addSubview(mainChart)
        view.addSubview(chartSegmentedControl)
        
        assetInfoView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.height.equalTo(40)
        }
        
        mainChart.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(view.snp.width).multipliedBy(0.8)
            make.top.equalTo(assetInfoView.snp.bottom).offset(8)
        }
        
        chartSegmentedControl.snp.makeConstraints { make in
            make.width.equalToSuperview().multipliedBy(0.9)
            make.height.equalTo(16)
            make.centerX.equalToSuperview()
            make.top.equalTo(mainChart.snp.bottom).offset(8)
        }
    }
        
        private func configureLeftBarButton() {
            let leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(popViewController))
            let assetLogoBarButtonItem = UIBarButtonItem(customView: barButtonView)
            navigationItem.leftBarButtonItems = [leftBarButtonItem, assetLogoBarButtonItem]
        }
    
    @objc private func popViewController() {
        navigationController?.popViewController(animated: true)
    }
    
    private func fetchPrice(for code: String, and exchange: String) {
        networkManager.getQuote(name: code, exchange: exchange) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let quote):
                    self.assetInfoView.configure(priceText: "\(quote.currentPrice)", descriptionText: "\(quote.currentDate)")
                    self.quote = quote
                case .failure(let error):
                    self.showAlert(title: error.title, message: error.description)
                }
            }
        }
    }
    
    
    
    private func fetchHistoricalData(assetName: String, exchange: String, from: String = Date().getHalfYearAgoDate().shortFormatString, to: String = Date().shortFormatString, period: Period = .day) {
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
                        let chartData = data.map { ChartEntryData(data: $0.close, date: $0.date)}
                        self.mainChart.chartData = chartData
                    case .failure(let error):
                        self.showAlert(title: error.title, message: error.description)
                    }
                }
            }
    }
    
    private func fetchIntradayHistoricalData(assetName: String, exchange: String, from: Double, to: Double, interval: IntraDayPeriod) {
        historicalDataNetworkManager.getIntradayHistoricalData(
            assetName: assetName,
            exchange: exchange,
            from: from,
            to: to,
            interval: interval) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    switch result {
                    case .success(let data):
                        // TODO: - Transform dateTime format for the label
                        let chartData = data.map { ChartEntryData(data: $0.close, date: $0.dateTime) }
                        self.mainChart.chartData = chartData
                    case .failure(let error):
                        self.showAlert(title: error.title, message: error.description)
                    }
                }
            }
    }
    
    @objc private func timeIntervalDidChange(_ segmentedControl: CustomSegmentedControl) {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            fetchHistoricalData(assetName: code ?? "", exchange: exchange ?? "", from: Date().getPreviousWeekDate().shortFormatString, to: Date().shortFormatString, period: .day)
        case 1:
            fetchHistoricalData(assetName: code ?? "", exchange: exchange ?? "", from: Date().getPreviousMonthDate().shortFormatString, to: Date().shortFormatString, period: .day)
        case 2:
            fetchHistoricalData(assetName: code ?? "", exchange: exchange ?? "", from: Date().getHalfYearAgoDate().shortFormatString, to: Date().shortFormatString, period: .day)
        case 3:
            fetchHistoricalData(assetName: code ?? "", exchange: exchange ?? "", from: Date().getYearAgoDate().shortFormatString, to: Date().shortFormatString, period: .day)
        default:
            fetchHistoricalData(assetName: code ?? "", exchange: exchange ?? "", from: Date().getTwoYearsAgoDate().shortFormatString, to: Date().shortFormatString, period: .day)
        }
        
    }
}

extension AssetViewController: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let marker = CircleMarker(color: .lightGray)
        mainChart.marker = marker
        assetInfoView.configure(priceText: "\(entry.y) \(currency ?? "")", descriptionText: "\(entry.data ?? "")")
    }
    
    func chartViewDidEndPanning(_ chartView: ChartViewBase) {
        chartView.highlightValues(nil)
        self.assetInfoView.configure(priceText: "\(quote?.currentPrice ?? 0)", descriptionText: "\(quote?.currentDate ?? "")")
    }

}
