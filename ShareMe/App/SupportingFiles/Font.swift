//
//  Font.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 23.08.2022.
//

import UIKit

struct Font {
    enum FontName: String {
        case Georgia         = "Georgia"
        case Baskerville     = "Baskerville"
        case BaskervilleBold = "Baskerville-Bold"
        case HelveticaBold   = "Helvetica-Bold"
    }
    enum StandardSize: Double {
        case s20 = 20.0
        case s18 = 18.0
        case s16 = 16.0
        case s14 = 14.0
        case s12 = 12.0
        case s10 = 10.0
    }
    
    enum FontType {
        case installed(FontName)
        case custom(String)
        case system
        case systemBold
        case systemItalic
    }
    
    enum FontSize {
        case standard(StandardSize)
        case custom(Double)
        
        var value: Double {
            switch self {
            case .standard(let size):
                return size.rawValue
            case .custom(let customSize):
                return customSize
            }
        }
    }
    
    var type: FontType
    var size: FontSize
    
    init(_ type: FontType, size: FontSize) {
        self.type = type
        self.size = size
    }
}

extension Font {
    var instance: UIFont {
        var instanceFont: UIFont!
        switch type {
        case .custom(let fontName):
            guard let font =  UIFont(name: fontName, size: CGFloat(size.value)) else {
                fatalError("\(fontName) font is not installed")
            }
            instanceFont = font
        case .installed(let fontName):
            guard let font =  UIFont(name: fontName.rawValue, size: CGFloat(size.value)) else {
                fatalError("\(fontName.rawValue) font is not installed")
            }
            instanceFont = font
        case .system:
            instanceFont = UIFont.systemFont(ofSize: CGFloat(size.value))
        case .systemBold:
            instanceFont = UIFont.boldSystemFont(ofSize: CGFloat(size.value))
        case .systemItalic:
            instanceFont = UIFont.italicSystemFont(ofSize: CGFloat(size.value))
        }
        return instanceFont
    }
}
