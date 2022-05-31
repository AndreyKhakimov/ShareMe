//
//  SectionHeaderView.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 31.05.2022.
//

import UIKit
import SnapKit

class SectionHeaderView: UICollectionReusableView {
    
    var label: UILabel = {
        let label = UILabel()
        label.textColor = .systemGray
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.sizeToFit()
        return label
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
        addSubview(label)
        
        label.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview()
        }
    }
}
