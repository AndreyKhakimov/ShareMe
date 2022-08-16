//
//  NewsTableViewCell.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 19.06.2022.
//

import Foundation
import UIKit
import SnapKit

class NewsTableViewCell: UITableViewCell {
    
    static let identifier = "NewsTableViewCell"
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Georgia", size: 12)
        label.textColor = .lightGray
        label.numberOfLines = 0
        label.textAlignment = .justified
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Georgia", size: 20)
        label.numberOfLines = 4
        label.textAlignment = .left
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(dateLabel)
        contentView.addSubview(titleLabel)
 
        
        dateLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.top.equalToSuperview().offset(2)
            make.bottom.equalTo(titleLabel.snp.top).offset(-2)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.top.equalTo(dateLabel.snp.bottom).offset(2)
            make.bottom.equalToSuperview().offset(-4)
        }
    }
    
    func configure(title: String, description: String) {
        dateLabel.text = title
        titleLabel.text = description
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        dateLabel.text = nil
        titleLabel.text = nil
    }
    
}
