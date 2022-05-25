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
        label.font = .systemFont(ofSize: 18, weight: .bold)
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 16)
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
        label.font = .systemFont(ofSize: 18, weight: .bold)
        return label
    }()
    
    private let priceChangeLabel: UILabel = {
        let label = UILabel()
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
        // TODO: - remove multipliedBy + top..bottom...
        logoImageView.snp.makeConstraints { make in
            make.height.equalToSuperview().multipliedBy(0.8)
            make.width.equalTo(contentView.snp.height).multipliedBy(0.8)
            make.centerY.equalToSuperview()
            make.left.equalTo(contentView.snp.left).offset(8)
        }
        
        assetNameLabel.snp.makeConstraints { make in
            make.left.equalTo(logoImageView.snp.right).offset(16)
            make.top.equalToSuperview().offset(8)
            make.height.equalToSuperview().multipliedBy(0.4)
            make.width.equalToSuperview().multipliedBy(0.2)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.left.equalTo(logoImageView.snp.right).offset(16)
            make.top.equalTo(assetNameLabel.snp.bottom).offset(2)
            make.height.equalToSuperview().multipliedBy(0.4)
            make.width.equalToSuperview().multipliedBy(0.2)
        }
        
        simpleChartView.snp.makeConstraints { make in
            make.height.equalToSuperview().multipliedBy(0.65)
            make.width.equalToSuperview().multipliedBy(0.25)
            make.centerY.equalToSuperview()
            make.left.equalTo(assetNameLabel.snp.right).offset(16)
        }
        
        priceLabel.snp.makeConstraints { make in
            make.left.equalTo(simpleChartView.snp.right).offset(8)
            make.top.equalToSuperview().offset(8)
            make.height.equalToSuperview().multipliedBy(0.3)
            make.width.equalToSuperview().multipliedBy(0.2)
        }
        
        priceChangeLabel.snp.makeConstraints { make in
            make.left.equalTo(simpleChartView.snp.right).offset(8)
            make.right.equalToSuperview().offset(-8)
            make.top.equalTo(priceLabel.snp.bottom).offset(2)
            make.height.equalToSuperview().multipliedBy(0.3)
//            make.width.equalToSuperview().multipliedBy(0.2)
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
        let formattedPrice = String(format: "%.2f", price)
        let formattedPriceChange = String(format: "%.2f", priceChange)
        let formattedPricePercentChange = String(format: "%.2f", pricePercentChange)

        if priceChange >= 0 {
            priceChangeLabel.textColor = .systemGreen
            priceChangeLabel.text = "+\(formattedPriceChange) \(currency), (\(formattedPricePercentChange)%)"
        } else {
            priceChangeLabel.textColor = .red
            priceChangeLabel.text = "\(formattedPriceChange) \(currency), (\(formattedPricePercentChange)%)"
        }
        priceLabel.text = formattedPrice
    }
    
}
