//
//  GrayscaleView.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 12.06.2022.
//

import UIKit

class GrayscaleView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = .tertiarySystemBackground
        layer.compositingFilter = "colorBlendMode"
    }

}
