//
//  ChartTableViewCell.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 23.06.2022.
//

import UIKit
import SnapKit

class ChartTableViewCell: UITableViewCell {
    
    static let identifier = "ChartTableViewCell"
    
    enum ChartState {
            case loading
            case data
        }
    
    enum ChartType {
        case line
        case candle
    }
    
    var callback: ((CustomSegmentedControl) -> Void)?
    
    var chartType: ChartType = .line {
        didSet {
            updateView()
        }
    }
    
    var chartState: ChartState = .loading {
        didSet {
            updateIndicatorView()
        }
    }
    
    lazy var assetInfoView: AssetInfoView = {
        let assetInfoView = AssetInfoView()
        return assetInfoView
    }()
    
    private lazy var shimmerView: ShimmerView = {
        let shimmerView = ShimmerView()
        return shimmerView
    }()
    
    // TODO: - Check dark mode color of grayscaleView
    private lazy var grayscaleView: GrayscaleView = {
        let grayscaleView = GrayscaleView()
        return grayscaleView
    }()
    
    lazy var mainChart: MainChartView = {
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
    
    lazy var mainCandleChart: CandleChartView = {
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
    
    lazy var chartSelectionButton: UIButton = {
        let chartSelectionButton = UIButton()
        chartSelectionButton.addTarget(self, action: #selector(configureChart), for: .touchUpInside)
        chartSelectionButton.backgroundColor = .lightGray.withAlphaComponent(0.2)
        chartSelectionButton.layer.cornerRadius = 10
        return chartSelectionButton
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        updateView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(assetInfoView)
        contentView.addSubview(mainChart)
        contentView.addSubview(mainCandleChart)
        contentView.addSubview(chartSegmentedControl)
        contentView.addSubview(chartSelectionButton)
        contentView.addSubview(grayscaleView)
        contentView.addSubview(shimmerView)
        selectionStyle = .none
        
        assetInfoView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(8)
            make.height.equalTo(40)
        }
        
        chartSelectionButton.snp.makeConstraints { make in
            make.left.equalTo(mainChart.snp.left).offset(8)
            make.top.equalTo(mainChart.snp.top).offset(8)
            make.height.width.equalTo(20)
        }
        
        mainChart.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.height.equalTo(contentView.snp.width).multipliedBy(0.8)
            make.top.equalTo(assetInfoView.snp.bottom).offset(8)
        }
        
        mainCandleChart.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.height.equalTo(contentView.snp.width).multipliedBy(0.8)
            make.top.equalTo(assetInfoView.snp.bottom).offset(8)
        }
        
        shimmerView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.top.equalTo(chartSelectionButton.snp.bottom)
            make.bottom.equalTo(mainChart)
        }
        
        grayscaleView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.top.equalTo(chartSelectionButton.snp.bottom)
            make.bottom.equalTo(mainChart)
        }
        
        chartSegmentedControl.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(mainChart.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }
    }
    
    func configure(chartState: ChartState, candleChartData: [CandleChartEntry]?, mainChartData: [ChartEntryData]) {
        
    }
    
    private func updateView() {
        switch chartType {
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
        chartType = chartType == .line ? .candle : .line
        timeIntervalDidChange(chartSegmentedControl)
        updateView()
    }
    
    @objc private func timeIntervalDidChange(_ segmentedControl: CustomSegmentedControl) {
        callback?(segmentedControl)
    }
    
    private func updateIndicatorView() {
        switch chartState {
        case .loading:
            shimmerView.isHidden = false
            grayscaleView.isHidden = false
            shimmerView.startAnimating()
        case .data:
            shimmerView.stopAnimating()
            shimmerView.isHidden = true
            grayscaleView.isHidden = true
        }
    }

}
