//
//  ShimmerView.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 09.06.2022.
//

import UIKit

class ShimmerView: UIView {
    
    private var gradientColorOne = UIColor(white: 1, alpha: 0).cgColor
    private var gradientColorTwo = UIColor(white: 1, alpha: 1).cgColor
    
    private var gradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        layer.addSublayer(gradientLayer)
        
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.colors = [gradientColorOne, gradientColorTwo, gradientColorOne]
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds

    }
    
    func addAnimation() -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue = [1.0, 1.5, 2.0]
        animation.repeatCount = .infinity
        animation.duration = 2
        return animation
    }
    
    func startAnimating() {
        let animation = addAnimation()
        gradientLayer.add(animation, forKey: animation.keyPath)
    }
    
    func stopAnimating() {
        gradientLayer.removeAllAnimations()
    }
    
}
