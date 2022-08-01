//
//  BarButtonView.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 10.05.2022.
//

import UIKit
import SnapKit

class BarButtonView: UIView {
    
    lazy var logoImageView: RoundedImageView = {
        let contentView = RoundedImageView(frame: .zero)
        return contentView
    }()
    
    lazy var logoLabel: InitialsLabel = {
        let logoLabel = InitialsLabel()
        logoLabel.clipsToBounds = true
        logoLabel.textColor = .white
        logoLabel.textAlignment = .center
        return logoLabel
    }()
    
    lazy var descriptionLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        descriptionLabel.textColor = .label
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
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
    
    private func setupView() {
        backgroundColor = .systemBackground
        setupLayout()
    }
    
    private func setupLayout() {
        addSubview(logoImageView)
        addSubview(logoLabel)
        addSubview(descriptionLabel)
        
        logoImageView.snp.makeConstraints { make in
            make.width.height.equalTo(30)
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
        }
        
        logoLabel.snp.makeConstraints { make in
            make.width.height.equalTo(30)
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.left.equalTo(logoImageView.snp.right).offset(8)
            make.right.equalToSuperview().offset(-16)
        }
    }
    
}
