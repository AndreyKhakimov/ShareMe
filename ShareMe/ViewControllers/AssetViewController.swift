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
    lazy var isFavourite: Bool = StorageManager.shared.checkAssetIsFavourite(code: code ?? "", exchange: exchange ?? "") {
        didSet {
            isFavourite ? setFavourite() : deleteFavourite()
            configureRightBarButton()
        }
    }
    var exchange: String?
    var currency: String?
    var type: AssetType?
    var logoURL: URL?
    var quote: Quote?
    
    private let networkManager = QuoteNetworkManager()
    private let historicalDataNetworkManager = HistoricalDataNetworkManager()
    private let storageManager = StorageManager.shared
    
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
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        hidesBottomBarWhenPushed = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        fetchPrice(for: code ?? "", and: exchange ?? "")
        fetchHistoricalData(assetName: code ?? "", exchange: exchange ?? "")
        mainChart.delegate = self
        configureLeftBarButton()
        configureRightBarButton()
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
    
    private func configureRightBarButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: isFavourite ? "star.fill" : "star"), style: .plain, target: self, action: #selector(toggleFavourite))
    }
    
    @objc private func popViewController() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func toggleFavourite() {
        isFavourite.toggle()
    }
    
    @objc private func setFavourite() {
        guard let code = code else { return }
        guard let exchange = exchange else { return }
        guard let type = type else { return }
        storageManager.saveAsset(code: code, exchange: exchange, type: type)
    }
    
    @objc private func deleteFavourite() {
        guard let code = code else { return }
        guard let exchange = exchange else { return }
        guard let asset = storageManager.getAsset(code: code, exchange: exchange) else { return }
        storageManager.deleteAsset(asset: asset)
    }
    
    private func fetchPrice(for code: String, and exchange: String) {
        networkManager.getQuote(name: code, exchange: exchange) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let quote):
                    self.assetInfoView.state = .staticPrice(price: quote.currentPrice, currency: self.currency ?? "", priceChange: quote.change, pricePercentChange: quote.changePercent)
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
        
        assetInfoView.state = .tracking(price: entry.y, currency: currency ?? "", descriptionText: entry.data as? String ?? "")
    }
    
    func chartViewDidEndPanning(_ chartView: ChartViewBase) {
        chartView.highlightValues(nil)
        
        assetInfoView.state = .staticPrice(price: quote?.currentPrice ?? 0, currency: currency ?? "", priceChange: quote?.change ?? 0, pricePercentChange: quote?.changePercent ?? 0)
    }
    
}
