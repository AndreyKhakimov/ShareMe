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
    
    static let identifier = "SearchResultTableViewCell"
    
    private let logoImageView: RoundedImageView = {
        let imageView = RoundedImageView(frame: CGRect())
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let logoLabel: InitialsLabel = {
        let logoLabel = InitialsLabel()
        logoLabel.clipsToBounds = true
        logoLabel.textColor = .white
        logoLabel.textAlignment = .center
        logoLabel.substringEndUp = ""
        return logoLabel
    }()
    
    private let searchResultLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .medium)
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
    
    private func setupViews() {
        contentView.addSubview(logoImageView)
        contentView.addSubview(logoLabel)
        contentView.addSubview(searchResultLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(simpleChartView)
        
        logoImageView.snp.makeConstraints { make in
            make.width.height.equalTo(32)
            make.left.top.equalTo(8)
        }
        
        logoLabel.snp.makeConstraints { make in
            make.width.height.equalTo(32)
            make.left.top.equalTo(8)
        }
        
        searchResultLabel.snp.makeConstraints { make in
            make.left.equalTo(logoImageView.snp.right).offset(16)
            make.top.equalToSuperview().offset(8)
            make.right.equalTo(simpleChartView.snp.left).offset(-8)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.left.equalTo(logoImageView.snp.right).offset(16)
            make.top.equalTo(searchResultLabel.snp.bottom).offset(2)
            make.right.equalTo(simpleChartView.snp.left).offset(-8)
            make.bottom.equalToSuperview().offset(-8)
        }
        
        simpleChartView.snp.makeConstraints { make in
            make.height.equalTo(32)
            make.width.equalTo(48)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-8)
        }
        
    }
    
    func configure(code: String, exchange: String, image: URL?, info: String, description: String, chartData: [Double]?) {
        let id = [code, exchange].joined(separator: ":")
        if let image = image {
            logoImageView.kf.setImage(with: image)
            logoLabel.isHidden = true
            logoImageView.isHidden = false
        } else if let cachedURL = logoImageCache.value(forKey: id) {
            logoImageView.kf.setImage(with: cachedURL)
        } else {
            logoLabel.string = code
            logoImageView.isHidden = true
            logoLabel.isHidden = false
        }
        searchResultLabel.text = info
        descriptionLabel.text = description
        if let chartData = chartData {
            simpleChartView.chartData = chartData
        }
    }
    
    override func prepareForReuse() {
        logoImageView.image = nil
        searchResultLabel.text = nil
        descriptionLabel.text = nil
    }
    
}
