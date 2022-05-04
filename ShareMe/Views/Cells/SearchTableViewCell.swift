//
//  SearchTableViewCell.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 24.04.2022.
//

import UIKit
import SnapKit
import Kingfisher

class SearchResultCell: UITableViewCell {
    
    static let identifier = "SearchResultSnpTableViewCell"
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    private let searchResultLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17,weight: .medium)
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    private let simpleChartView: SimpleChartView = {
        let simpleChart =  SimpleChartView()
        simpleChart.lineColor = .green
        simpleChart.gradientColor = .green.withAlphaComponent(0.5)
        return simpleChart
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //    override func layoutSubviews() {
    //        super.layoutSubviews()
    //
    //        let imageSize = contentView.frame.size.height - 5
    //
    //
    //        logoImageView.frame = CGRect(x: 5,
    //                                     y: 5,
    //                                     width: imageSize,
    //                                     height: imageSize)
    //        searchResultLabel.frame = CGRect(x: 10 + logoImageView.frame.size.width - 10,
    //                                         y: 5,
    //                                         width: contentView.frame.size.width - imageSize - 10,
    //                                         height: contentView.frame.size.height-10)
    //    }
    
    // TODO: - Change offsets to 8
    private func setupViews() {
        contentView.addSubview(logoImageView)
        contentView.addSubview(searchResultLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(simpleChartView)
        
        logoImageView.snp.makeConstraints { make in
            make.width.height.equalTo(32)
            make.left.top.equalTo(6)
        }
        
        searchResultLabel.snp.makeConstraints { make in
            make.left.equalTo(logoImageView.snp.right).offset(16)
            make.top.equalToSuperview().offset(6)
            make.right.equalTo(simpleChartView.snp.left).offset(-6)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.left.equalTo(logoImageView.snp.right).offset(16)
            make.top.equalTo(searchResultLabel.snp.bottom).offset(2)
            make.right.equalTo(simpleChartView.snp.left).offset(-6)
            make.bottom.equalToSuperview().offset(-6)
        }
        
        simpleChartView.snp.makeConstraints { make in
            make.height.equalTo(32)
            make.width.equalTo(48)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-6)
        }
        
    }
    
    func configure(image: URL?, info: String, description: String, chartData: [Double]?) {
        if let image = image {
            logoImageView.kf.setImage(with: image)
        } else {
            logoImageView.image = UIImage(systemName: "photo.artframe")
        }
        searchResultLabel.text = info
        descriptionLabel.text = description
        if let chartData = chartData {
            simpleChartView.chartData = chartData
        }
    }
    
}
