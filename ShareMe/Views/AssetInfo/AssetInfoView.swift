//
//  AssetInfoView.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 14.05.2022.
//

import UIKit
import SnapKit

enum AssetInfoViewState {
    case staticPrice(price: Double, currency: String, priceChange: Double , pricePercentChange: Double)
    case tracking(price: Double, currency: String, descriptionText: String)
}

class AssetInfoView: UIView {
    
    var state: AssetInfoViewState = .staticPrice(price: 0, currency: "", priceChange: 0, pricePercentChange: 0) {
        didSet {
            configure()
            updateView()
        }
    }
    
    private lazy var priceLabel: UILabel = {
        let priceLabel = UILabel()
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        return priceLabel
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        return descriptionLabel
    }()
    
    //    var staticConstraints = [NSLayoutConstraint]()
    //    var trackingConstraints = [NSLayoutConstraint]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    func configure() {
        switch state {
        case .staticPrice(let price, let currency, let priceChange, let pricePercentChange):
            let formattedPrice = String(format: "%.2f", price)
            let formattedPriceChange = String(format: "%.2f", priceChange)
            let formattedPricePercentChange = String(format: "%.2f", pricePercentChange)
            
            priceLabel.text = "\(formattedPrice) \(currency)"
            
            if priceChange >= 0 {
                descriptionLabel.textColor = .systemGreen
                descriptionLabel.text = "+ \(formattedPriceChange) \(currency), (\(formattedPricePercentChange)%)"
            } else {
                descriptionLabel.textColor = .red
                descriptionLabel.text = "\(formattedPriceChange) \(currency), (\(formattedPricePercentChange)%)"
            }
        case .tracking(let price, let currency, let descriptionText):
            let formattedPrice = String(format: "%.2f", price)
            
            priceLabel.text = "\(formattedPrice) \(currency)"
            descriptionLabel.textColor = .lightGray
            descriptionLabel.text = descriptionText
        }
    }
    
    private func setupView() {
        addSubview(priceLabel)
        addSubview(descriptionLabel)
        
        priceLabel.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(25)
            make.left.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(15)
            make.left.equalToSuperview()
            make.top.equalTo(priceLabel.snp.bottom).offset(2)
        }
    }
    
    private func updateView() {
        switch state {
        case .staticPrice:
            priceLabel.snp.remakeConstraints { make in
                make.width.equalToSuperview()
                make.height.equalTo(25)
                make.left.equalToSuperview()
                make.top.equalToSuperview()
            }
            
            descriptionLabel.snp.remakeConstraints { make in
                make.width.equalToSuperview()
                make.height.equalTo(15)
                make.left.equalToSuperview()
                make.top.equalTo(priceLabel.snp.bottom).offset(2)
            }
            
            descriptionLabel.textAlignment = .left
            priceLabel.textAlignment = .left
        case .tracking:
            descriptionLabel.snp.remakeConstraints { make in
                make.width.equalToSuperview()
                make.height.equalTo(25)
                make.left.equalToSuperview()
                make.top.equalToSuperview()
            }
            
            priceLabel.snp.remakeConstraints { make in
                make.width.equalToSuperview()
                make.height.equalTo(15)
                make.left.equalToSuperview()
                make.top.equalTo(descriptionLabel.snp.bottom).offset(2)
            }
            
            descriptionLabel.textAlignment = .center
            priceLabel.textAlignment = .center
        }
    }
    
}
