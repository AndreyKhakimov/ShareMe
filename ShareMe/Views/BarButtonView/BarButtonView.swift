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
        contentView.translatesAutoresizingMaskIntoConstraints = false
        return contentView
    }()
    
    lazy var descriptionLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
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
    
    private func setupView() {
        backgroundColor = .white
        setupLayout()
    }
    
    private func setupLayout() {
        addSubview(logoImageView)
        addSubview(descriptionLabel)
        
        logoImageView.snp.makeConstraints { make in
            make.width.height.equalTo(30)
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.centerY.equalTo(logoImageView)
            make.left.equalTo(logoImageView.snp.right).offset(8)
            make.right.equalToSuperview().offset(-16)
//            make.height.equalTo(27)
        }
    }
    
}
