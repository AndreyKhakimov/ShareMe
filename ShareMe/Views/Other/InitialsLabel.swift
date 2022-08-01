//
//  InitialsLabel.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 22.07.2022.
//

import UIKit

class InitialsLabel: UILabel {
    
    var string: String = "" {
        didSet {
            backgroundColor = generateColorFor(text: string)
            text = getFirstPartFromString(for: string, substringEndUp: substringEndUp)
        }
    }
    
    var substringEndUp: String = ""
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.size.width / 2
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = generateColorFor(text: string)
    }
    
    private func getFirstPartFromString(for string: String, substringEndUp: String) -> String {
        if let range = string.range(of: substringEndUp) {
            let firstPart = string[string.startIndex..<range.lowerBound]
            guard firstPart.count < 3 else { return String(String(firstPart).prefix(3)) }
            return firstPart.uppercased()
        } else {
            return String(string.prefix(3))
        }
    }
    
    private func generateColorFor(text: String) -> UIColor {
        var hash = 0
        let colorConstant = 131
        let maxSafeValue = Int.max / colorConstant
        for char in text.unicodeScalars{
            if hash > maxSafeValue {
                hash = hash / colorConstant
            }
            hash = Int(char.value) + ((hash << 5) - hash)
        }
        let finalHash = abs(hash) % (256 * 256 * 256);
        let color = UIColor(red: CGFloat((finalHash & 0xFF0000) >> 16) / 255.0, green: CGFloat((finalHash & 0xFF00) >> 8) / 255.0, blue: CGFloat((finalHash & 0xFF)) / 255.0, alpha: 1.0)
        return color
    }
    
}

