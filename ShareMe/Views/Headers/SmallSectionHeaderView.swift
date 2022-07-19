//
//  SmallSectionHeaderView.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 19.07.2022.
//

import UIKit
import SnapKit

class SmallSectionHeaderView: UICollectionReusableView {
    
    var label: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
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
            make.left.equalToSuperview().offset(8)
            make.top.equalToSuperview()
        }
    }
}
