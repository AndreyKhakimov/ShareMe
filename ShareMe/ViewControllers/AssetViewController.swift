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

protocol AssetViewControllerDelegate: AnyObject {
    func didToggleFavorite()
}

class AssetViewController: UIViewController {
    
    weak var delegate: AssetViewControllerDelegate?
    var code: String?
    var assetName: String?
    lazy var isFavourite: Bool = StorageManager.shared.checkAssetIsFavourite(code: code ?? "", exchange: exchange ?? "") {
        didSet {
            isFavourite ? setFavourite() : deleteFavourite()
            configureRightBarButton()
        }
    }
    
    private var chartState: ChartState = .line {
            didSet {
                updateView()
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
        mainChart.setScaleEnabled(false)
        mainChart.pinchZoomEnabled = false
        mainChart.highlightPerTapEnabled = false
        mainChart.xAxis.enabled = false
        mainChart.rightAxis.enabled = false
        mainChart.leftAxis.enabled = false
        mainChart.legend.enabled = false
        return mainChart
    }()
    
    private lazy var mainCandleChart: CandleChartView = {
        let candleChart =  CandleChartView()
        candleChart.setScaleEnabled(false)
        candleChart.pinchZoomEnabled = false
        candleChart.xAxis.enabled = false
        candleChart.rightAxis.enabled = false
        candleChart.leftAxis.enabled = false
        candleChart.legend.enabled = false
        return candleChart
    }()
    
    private lazy var chartSegmentedControl: CustomSegmentedControl = {
        let items = ["W" ,"M", "6M", "1Y", "All"]
        let segmentedControl = CustomSegmentedControl()
        segmentedControl.items = items
        segmentedControl.selectedSegmentIndex = 2
        segmentedControl.addTarget(self, action: #selector(timeIntervalDidChange(_:)), for: .valueChanged)
        return segmentedControl
    }()
    
    private lazy var chartSelectionButton: UIButton = {
        let chartSelectionButton = UIButton()
        chartSelectionButton.addTarget(self, action: #selector(configureChart), for: .touchUpInside)
        chartSelectionButton.backgroundColor = .lightGray.withAlphaComponent(0.2)
        chartSelectionButton.layer.cornerRadius = 10
        return chartSelectionButton
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
        updateView()
        fetchPrice(for: code ?? "", and: exchange ?? "")
        fetchHistoricalData(assetName: code ?? "", exchange: exchange ?? "")
        mainChart.delegate = self
        mainCandleChart.delegate = self
        configureLeftBarButton()
        configureRightBarButton()
    }
    
    private func setupViews() {
        view.backgroundColor = .white
        view.addSubview(assetInfoView)
        view.addSubview(mainChart)
        view.addSubview(mainCandleChart)
        view.addSubview(chartSegmentedControl)
        view.addSubview(chartSelectionButton)
        
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
        
        mainCandleChart.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(view.snp.width).multipliedBy(0.8)
            make.top.equalTo(assetInfoView.snp.bottom).offset(8)
        }
        
        chartSelectionButton.snp.makeConstraints { make in
            make.left.equalTo(mainChart.snp.left).offset(8)
            make.top.equalTo(mainChart.snp.top).offset(8)
            make.height.width.equalTo(20)
        }
        
        chartSegmentedControl.snp.makeConstraints { make in
            make.width.equalToSuperview().multipliedBy(0.9)
            make.height.equalTo(16)
            make.centerX.equalToSuperview()
            make.top.equalTo(mainChart.snp.bottom).offset(8)
        }
    }
    
    private func updateView() {
        switch chartState {
        case .line:
            mainCandleChart.isHidden = true
            mainChart.isHidden = false
            chartSelectionButton.setImage(UIImage(systemName: "chart.xyaxis.line"), for: .normal)
        case .candle:
            mainCandleChart.isHidden = false
            mainChart.isHidden = true
            chartSelectionButton.setImage(UIImage(systemName: "chart.bar.xaxis"), for: .normal)
        }
    }
    
    @objc private func configureChart() {
        chartState = chartState == .line ? .candle : .line
        updateView()
    }
    
    private func configureLeftBarButton() {
        let leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(popViewController))
        let assetLogoBarButtonItem = UIBarButtonItem(customView: barButtonView)
        let isFirst = navigationController?.viewControllers.count == 1
        navigationItem.leftBarButtonItems = isFirst ? [assetLogoBarButtonItem] : [leftBarButtonItem, assetLogoBarButtonItem]
    }
    
    private func configureRightBarButton() {
        let rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(closeViewController))
        let favoriteBarButtonItem = UIBarButtonItem(image: UIImage(systemName: isFavourite ? "star.fill" : "star"), style: .plain, target: self, action: #selector(toggleFavourite))
        let isFirst = navigationController?.viewControllers.count == 1
        navigationItem.rightBarButtonItems = isFirst ? [rightBarButtonItem, favoriteBarButtonItem] : [favoriteBarButtonItem]
    }
    
    @objc private func popViewController() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func closeViewController() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc private func toggleFavourite() {
        isFavourite.toggle()
    }
    
    @objc private func setFavourite() {
        guard let code = code else { return }
        guard let exchange = exchange else { return }
        guard let type = type else { return }
        
        storageManager.saveAsset(code: code, exchange: exchange, type: type)
        delegate?.didToggleFavorite()
    }
    
    @objc private func deleteFavourite() {
        guard let code = code else { return }
        guard let exchange = exchange else { return }
        guard let asset = storageManager.getAsset(code: code, exchange: exchange) else { return }
        
        storageManager.deleteAsset(asset: asset)
        delegate?.didToggleFavorite()
    }
    
    private func fetchPrice(for code: String, and exchange: String) {
        networkManager.getQuote(name: code, exchange: exchange) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let quote):
                    self.assetInfoView.state = .staticPrice(price: quote.currentPrice, currency: self.currency ?? "", priceChange: quote.priceChange, pricePercentChange: quote.changePercent)
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
                        let candleChartData = data.map { CandleChartEntry(date: $0.date, open: $0.open, high: $0.high, low: $0.low, close: $0.close, volume: $0.volume) }
                        self.mainChart.chartData = chartData
                        self.mainCandleChart.chartData = candleChartData
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
                        let chartData = data.map { ChartEntryData(data: $0.close, date: $0.dateTime) }
                        let candleChartData = data.map { CandleChartEntry(date: $0.dateTime, open: $0.open, high: $0.high, low: $0.low, close: $0.close, volume: $0.volume ?? 0) }
                        self.mainChart.chartData = chartData
                        self.mainCandleChart.chartData = candleChartData
                    case .failure(let error):
                        self.showAlert(title: error.title, message: error.description)
                    }
                }
            }
    }
    // TODO: - create array of structs
    @objc private func timeIntervalDidChange(_ segmentedControl: CustomSegmentedControl) {
        switch (segmentedControl.selectedSegmentIndex, chartState) {
        case (0, .line):
            fetchIntradayHistoricalData(assetName: code ?? "", exchange: exchange ?? "", from: Date().getPreviousWeekDate().timeIntervalSince1970 , to: Date().timeIntervalSince1970, interval: .hour)
        case (0, .candle):
            fetchIntradayHistoricalData(assetName: code ?? "", exchange: exchange ?? "", from: Date().getPreviousWeekDate().timeIntervalSince1970 , to: Date().timeIntervalSince1970, interval: .hour)
        case (1, .line):
            fetchIntradayHistoricalData(assetName: code ?? "", exchange: exchange ?? "", from: Date().getPreviousMonthDate().timeIntervalSince1970 , to: Date().timeIntervalSince1970, interval: .hour)
        case (1, .candle):
            fetchHistoricalData(assetName: code ?? "", exchange: exchange ?? "", from: Date().getHalfYearAgoDate().shortFormatString, to: Date().shortFormatString, period: .day)
        case (2, .line):
            fetchHistoricalData(assetName: code ?? "", exchange: exchange ?? "", from: Date().getHalfYearAgoDate().shortFormatString, to: Date().shortFormatString, period: .day)
        case (2, .candle):
            fetchHistoricalData(assetName: code ?? "", exchange: exchange ?? "", from: Date().getHalfYearAgoDate().shortFormatString, to: Date().shortFormatString, period: .week)
        case (3, .line):
            fetchHistoricalData(assetName: code ?? "", exchange: exchange ?? "", from: Date().getYearAgoDate().shortFormatString, to: Date().shortFormatString, period: .day)
        case (3, .candle):
            fetchHistoricalData(assetName: code ?? "", exchange: exchange ?? "", from: Date().getYearAgoDate().shortFormatString, to: Date().shortFormatString, period: .week)
        default:
            fetchHistoricalData(assetName: code ?? "", exchange: exchange ?? "", from: Date().getTwoYearsAgoDate().shortFormatString, to: Date().shortFormatString, period: .month)
        }
    }
}

extension AssetViewController: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let marker = CircleMarker(color: .lightGray)
        mainChart.marker = marker
        let candleMarker = PillMarker(color: .systemRed, font: .systemFont(ofSize: 14), textColor: .brown)
        candleMarker.chartView = mainCandleChart
        mainCandleChart.marker = candleMarker
        let CandleChartDataEntry = (entry as? CandleChartDataEntry)?.data as? CandleChartEntry
        chartSelectionButton.isHidden = true
        
        switch chartState {
        case .line:
            assetInfoView.state = .tracking(
                price: entry.y, currency: currency ?? "",
                descriptionText: entry.data as? String ?? ""
            )
        case .candle:
            assetInfoView.state = .candleTracking(
                currency: currency ?? "",
                priceChange: CandleChartDataEntry?.priceChange ?? 0 ,
                pricePercentChange: CandleChartDataEntry?.pricePercentChange ?? 0,
                descriptionText: CandleChartDataEntry?.timeIntervalDescription ?? "")
        }
    }
    
    func chartViewDidEndPanning(_ chartView: ChartViewBase) {
        chartView.highlightValues(nil)
        
        chartSelectionButton.isHidden = false
        
        switch chartState {
        case .line:
            assetInfoView.state = .staticPrice(price: quote?.currentPrice ?? 0, currency: currency ?? "", priceChange: quote?.priceChange ?? 0, pricePercentChange: quote?.changePercent ?? 0)
        case .candle:
            assetInfoView.state = .staticPrice(price: quote?.currentPrice ?? 0, currency: currency ?? "", priceChange: quote?.priceChange ?? 0, pricePercentChange: quote?.changePercent ?? 0)
        }
    }
    
}

fileprivate enum ChartState {
    case line
    case candle
}
