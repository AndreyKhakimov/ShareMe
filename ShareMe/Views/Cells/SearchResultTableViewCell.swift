//
//  SearchResultTableViewCell.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 21.04.2022.
//

import UIKit
import Kingfisher

class SearchResultTableViewCell: UITableViewCell {
    
    @IBOutlet weak var logoImageView: RoundedImageView!
    @IBOutlet weak var searchResultLabel: UILabel!
    
    func configure(image: URL?, info: String) {
        if let image = image {
            logoImageView.kf.setImage(with: image)
        } else {
            logoImageView.image = UIImage(systemName: "photo.artframe")
        }
        searchResultLabel.text = info
    }
    
}
