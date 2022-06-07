//
//  PortfolioCollectionViewCell.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 25.05.2022.
//

import UIKit
import SnapKit
import Kingfisher

class PortfolioCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "PortfolioCollectionViewCell"
    
    private let logoImageView: RoundedImageView = {
        let imageView = RoundedImageView(frame: CGRect())
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let assetNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 12)
        return label
    }()
    
    private let simpleChartView: SimpleChartView = {
        let simpleChart =  SimpleChartView()
        simpleChart.lineColor = .green
        simpleChart.gradientColor = .green.withAlphaComponent(0.5)
        return simpleChart
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.font = .systemFont(ofSize: 16, weight: .bold)
        return label
    }()
    
    private let priceChangeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(logoImageView)
        contentView.addSubview(assetNameLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(simpleChartView)
        contentView.addSubview(priceLabel)
        contentView.addSubview(priceChangeLabel)
        
        logoImageView.snp.makeConstraints { make in
            make.height.width.equalTo(48)
            make.left.equalToSuperview().offset(8)
            make.top.equalToSuperview()
        }
        
        assetNameLabel.snp.makeConstraints { make in
            make.left.equalTo(logoImageView.snp.right).offset(16)
            make.top.equalToSuperview()
            make.height.equalTo(28)
            make.width.equalTo(90)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.left.equalTo(logoImageView.snp.right).offset(16)
            make.top.equalTo(assetNameLabel.snp.bottom).offset(4)
            make.height.equalTo(16)
            make.width.equalTo(90)
        }
        
        simpleChartView.snp.makeConstraints { make in
            make.height.equalToSuperview()
            make.left.equalTo(assetNameLabel.snp.right).offset(8)
            make.right.equalTo(priceLabel.snp.left).offset(-8)
        }
        
        priceLabel.snp.makeConstraints { make in
            make.left.equalTo(simpleChartView.snp.right).offset(8)
            make.right.equalToSuperview().offset(-8)
            make.top.equalToSuperview()
            make.height.equalTo(28)
            make.width.equalTo(100)
        }
        
        priceChangeLabel.snp.makeConstraints { make in
            make.left.equalTo(simpleChartView.snp.right).offset(8)
            make.right.equalToSuperview().offset(-8)
            make.top.equalTo(priceLabel.snp.bottom).offset(4)
            make.height.equalTo(16)
            make.width.equalTo(100)
        }
    }
    
    func configure(logo: URL?, assetName: String, assetDescription: String, chartData: [Double]?, price: Double, currency: String, priceChange: Double, pricePercentChange: Double) {
        if let logo = logo {
            logoImageView.kf.setImage(with: logo)
        } else {
            logoImageView.image = UIImage(systemName: "photo.artframe")
        }
        assetNameLabel.text = assetName
        descriptionLabel.text = assetDescription
        
        if let chartData = chartData {
            simpleChartView.chartData = chartData
        }
        
        switch price {
        case 10000... :
            priceLabel.text = "\(String(format: "%.f", price)) \(currency)"
        default:
            priceLabel.text = "\(String(format: "%.2f", price)) \(currency)"
            
        }
        
        let formattedPricePercentChange = String(format: "%.2f", pricePercentChange)
        
        if priceChange >= 0 {
            simpleChartView.lineColor = .systemGreen
            simpleChartView.gradientColor = .systemGreen
            priceChangeLabel.textColor = .systemGreen
            priceChangeLabel.text = "+\(formattedPricePercentChange) %"
        } else {
            simpleChartView.lineColor = .systemRed
            simpleChartView.gradientColor = .systemRed
            priceChangeLabel.textColor = .red
            priceChangeLabel.text = "\(formattedPricePercentChange) %"
        }
    }
    
}