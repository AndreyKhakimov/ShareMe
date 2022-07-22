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
    
    private enum Section {
        case chart, news
    }
    
    var code: String?
    var assetName: String?
    var exchange: String?
    var currency: String?
    var type: AssetType?
    var logoURL: URL?
    var quote: Quote?
    var news = [NewsResponse]()
    let chartTableViewCell = ChartTableViewCell()
    
    private let sections: [Section] = [.chart, .news]
    
    lazy var isFavourite: Bool = StorageManager.shared.checkAssetIsFavourite(code: code ?? "", exchange: exchange ?? "") {
        didSet {
            isFavourite ? setFavourite() : deleteFavourite()
            configureRightBarButton()
        }
    }
    
    private struct AssetRequestInfo {
        let period: String
        let daysAgo: Int
    }
    
    private var lineChartAssetRequestInfo: [AssetRequestInfo] = [
        AssetRequestInfo(period: IntraDayPeriod.hour.rawValue, daysAgo: 7),
        AssetRequestInfo(period: IntraDayPeriod.hour.rawValue, daysAgo: 30),
        AssetRequestInfo(period: Period.day.rawValue, daysAgo: 180),
        AssetRequestInfo(period: Period.day.rawValue, daysAgo: 365),
        AssetRequestInfo(period: Period.month.rawValue, daysAgo: 1460),
    ]
    
    private var candleChartAssetRequestInfo: [AssetRequestInfo] = [
        AssetRequestInfo(period: IntraDayPeriod.hour.rawValue, daysAgo: 7),
        AssetRequestInfo(period: Period.day.rawValue, daysAgo: 30),
        AssetRequestInfo(period: Period.week.rawValue, daysAgo: 180),
        AssetRequestInfo(period: Period.week.rawValue, daysAgo: 365),
        AssetRequestInfo(period: Period.month.rawValue, daysAgo: 1460),
    ]
    
    private let networkManager = QuoteNetworkManager()
    private let historicalDataNetworkManager = HistoricalDataNetworkManager()
    private let storageManager = StorageManager.shared
    
    private lazy var barButtonView: BarButtonView = {
        let barButtonView = BarButtonView()
        if let logoURL = logoURL {
            barButtonView.logoImageView.kf.setImage(with: logoURL)
        } else {
            // TODO: - Fix the absence of image
            barButtonView.logoImageView.setImageForName(assetName!,
                                                        substringEndUp: "",
                                                        backgroundColor: nil,
                                                        circular: true,
                                                        textAttributes: nil,
                                                        gradientColors: nil
            )
        }
        barButtonView.descriptionLabel.text = assetName
        return barButtonView
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.estimatedRowHeight = 100
        tableView.estimatedSectionHeaderHeight = 30
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.register(NewsTableViewCell.self, forCellReuseIdentifier: NewsTableViewCell.identifier)
        return tableView
    }()
    
    // MARK: - Init
    init(code: String, assetName: String, exchange: String, currency: String, type: AssetType, logoURL: URL?) {
        self.code = code
        self.assetName = assetName
        self.exchange = exchange
        self.currency = currency
        self.type = type
        self.logoURL = logoURL
        
        super.init(nibName: nil, bundle: nil)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        hidesBottomBarWhenPushed = true
    }
    
    // MARK: - Override
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        navigationController?.navigationBar.backgroundColor = .systemBackground
        // TODO: - Remove gap between navBar and section
        tableView.tableHeaderView = UIView(frame: CGRect(x: .zero, y: .zero, width: .zero, height: CGFloat.leastNonzeroMagnitude))
        fetchPrice(for: code ?? "", and: exchange ?? "")
        fetchHistoricalData(assetName: code ?? "", exchange: exchange ?? "", from: Date().getDateForDaysAgo(180).shortFormatString, to: Date().shortFormatString, period: Period.day.rawValue)
        fetchNews(for: code ?? "", and: exchange ?? "")
        chartTableViewCell.mainChart.delegate = self
        chartTableViewCell.mainCandleChart.delegate = self
        chartTableViewCell.callback = { [weak self] segmentedControl in
            guard let self = self else { return }
            switch self.chartTableViewCell.chartType {
            case .line:
                let lineChartRequestInfo = self.lineChartAssetRequestInfo[segmentedControl.selectedSegmentIndex]
                self.fetchData(
                    period: lineChartRequestInfo.period,
                    daysAgo: lineChartRequestInfo.daysAgo
                )
            case .candle:
                let candleChartRequestInfo = self.candleChartAssetRequestInfo[segmentedControl.selectedSegmentIndex]
                self.fetchData(
                    period: candleChartRequestInfo.period,
                    daysAgo: candleChartRequestInfo.daysAgo
                )
            }
        }
        tableView.delegate = self
        tableView.dataSource = self
        configureLeftBarButton()
        configureRightBarButton()
    }
    
    private func setupViews() {
        view.backgroundColor = .white
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.bottom.equalToSuperview()
        }
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
        guard let name = assetName else { return }
        guard let currency = currency else { return }
        
        storageManager.saveAsset(code: code, exchange: exchange, type: type, name: name, currency: currency)
    }
    
    @objc private func deleteFavourite() {
        guard let code = code else { return }
        guard let exchange = exchange else { return }
        guard let asset = storageManager.getAsset(code: code, exchange: exchange) else { return }
        
        storageManager.deleteAsset(asset: asset)
    }
    
    // MARK: - Fetch methods
    private func fetchPrice(for code: String, and exchange: String) {
        networkManager.getQuote(name: code, exchange: exchange) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let quote):
                    self.chartTableViewCell.assetInfoView.state = .staticPrice(price: quote.currentPrice, currency: self.currency ?? "", priceChange: quote.priceChange, pricePercentChange: quote.changePercent)
                    self.quote = quote
                case .failure(let error):
                    self.showAlert(title: error.title, message: error.description)
                }
            }
        }
    }
    
    private func fetchHistoricalData(assetName: String, exchange: String, from: String, to: String, period: String) {
        chartTableViewCell.chartState = .loading
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
                        self.chartTableViewCell.mainChart.chartData = chartData
                        self.chartTableViewCell.mainCandleChart.chartData = candleChartData
                        self.chartTableViewCell.chartState = .data
                    case .failure(let error):
                        self.showAlert(title: error.title, message: error.description)
                    }
                }
            }
    }
    
    private func fetchIntradayHistoricalData(assetName: String, exchange: String, from: Double, to: Double, interval: String) {
        chartTableViewCell.chartState = .loading
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
                        self.chartTableViewCell.mainChart.chartData = chartData
                        self.chartTableViewCell.mainCandleChart.chartData = candleChartData
                        self.chartTableViewCell.chartState = .data
                    case .failure(let error):
                        self.showAlert(title: error.title, message: error.description)
                    }
                }
            }
    }
    
    private func fetchNews(for code: String, and exchange: String) {
        historicalDataNetworkManager.getNewsForAsset(assetName: code, exchange: exchange) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let news):
                    self.news = news
                    self.tableView.reloadData()
                case .failure(let error):
                    self.showAlert(title: error.title, message: error.description)
                }
            }
        }
        
    }
    
    private func fetchData(period: String, daysAgo: Int) {
        if let _ = IntraDayPeriod(rawValue: period) {
            fetchIntradayHistoricalData(assetName: code ?? "", exchange: exchange ?? "", from: Date().getDateForDaysAgo(daysAgo).timeIntervalSince1970, to: Date().timeIntervalSince1970, interval: period)
        } else {
            fetchHistoricalData(assetName: code ?? "", exchange: exchange ?? "", from: Date().getDateForDaysAgo(daysAgo).shortFormatString, to: Date().shortFormatString, period: period)
        }
    }
    
}

// MARK: - ChartView Delegate methods
extension AssetViewController: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let marker = CircleMarker(color: .lightGray)
        chartTableViewCell.mainChart.marker = marker
        let candleMarker = PillMarker(color: .systemRed, font: .systemFont(ofSize: 14), textColor: .brown)
        candleMarker.chartView = chartTableViewCell.mainCandleChart
        chartTableViewCell.mainCandleChart.marker = candleMarker
        let CandleChartDataEntry = (entry as? CandleChartDataEntry)?.data as? CandleChartEntry
        chartTableViewCell.chartSelectionButton.isHidden = true
        
        switch chartTableViewCell.chartType {
        case .line:
            chartTableViewCell.assetInfoView.state = .tracking(
                price: entry.y, currency: currency ?? "",
                descriptionText: entry.data as? String ?? ""
            )
        case .candle:
            chartTableViewCell.assetInfoView.state = .candleTracking(
                currency: currency ?? "",
                priceChange: CandleChartDataEntry?.priceChange ?? 0 ,
                pricePercentChange: CandleChartDataEntry?.pricePercentChange ?? 0,
                descriptionText: CandleChartDataEntry?.timeIntervalDescription ?? "")
        }
    }
    
    func chartViewDidEndPanning(_ chartView: ChartViewBase) {
        chartView.highlightValues(nil)
        
        chartTableViewCell.chartSelectionButton.isHidden = false
        
        switch chartTableViewCell.chartType {
        case .line:
            chartTableViewCell.assetInfoView.state = .staticPrice(price: quote?.currentPrice ?? 0, currency: currency ?? "", priceChange: quote?.priceChange ?? 0, pricePercentChange: quote?.changePercent ?? 0)
        case .candle:
            chartTableViewCell.assetInfoView.state = .staticPrice(price: quote?.currentPrice ?? 0, currency: currency ?? "", priceChange: quote?.priceChange ?? 0, pricePercentChange: quote?.changePercent ?? 0)
        }
    }
    
}

// MARK: - UITableViewDelegate, UITableViewDataSource methods
extension AssetViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionItem = sections[section]
        switch sectionItem {
        case .chart:
            return 1
        case .news:
            return news.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionItem = sections[indexPath.section]
        switch sectionItem {
        case .chart:
            return chartTableViewCell
        case .news:
            let cell = tableView.dequeueReusableCell(withIdentifier: NewsTableViewCell.identifier, for: indexPath) as! NewsTableViewCell
            let pieceOfNews = news[indexPath.row]
            cell.configure(title: pieceOfNews.title, description: pieceOfNews.content)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionItem = sections[section]
        switch sectionItem {
        case .chart:
            return nil
        case .news:
            return "\(assetName ?? "") news"
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sectionItem = sections[indexPath.section]
        switch sectionItem {
        case .chart:
            return
        case .news:
            let pieceOfNews = news[indexPath.row]
            guard let url = URL(string: pieceOfNews.link) else { return }
            let vc = WebViewViewController(url: url)
            let navVC = UINavigationController(rootViewController: vc)
            present(navVC, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let sectionItem = sections[section]
        
        switch sectionItem {
        case .chart:
            return CGFloat.leastNormalMagnitude
        case .news:
            return 30
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionItem = sections[section]
        
        switch sectionItem {
        case .chart:
            return nil
        case .news:
            let headerView = SmallSectionHeaderView()
            headerView.label.text = "News"
            return headerView
        }
    }
    
}
