//
//  AssetInfoView.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 14.05.2022.
//

import UIKit
import SnapKit

enum AssetInfoViewState {
    case staticPrice
    case tracking
}

class AssetInfoView: UIView {
    
    var state: AssetInfoViewState = .staticPrice {
        didSet {
            setupView()
        }
    }
    
    private lazy var priceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        return descriptionLabel
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    func configure(priceText: String, descriptionText: String) {
        priceLabel.text = priceText
        descriptionLabel.text = descriptionText
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
    
}
