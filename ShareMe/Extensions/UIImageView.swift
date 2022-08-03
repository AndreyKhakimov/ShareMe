//
//  UIImageView.swift
//  ShareMe
//
//  Created by Andrey Khakimov on 01.08.2022.
//

import UIKit

let kFontResizingProportion: CGFloat = 0.4
let kColorMinComponent: Int = 30
let kColorMaxComponent: Int = 214

extension UIImageView {
    
    
    func setImageForName(
        _ string: String,
        substringEndUp: String,
        backgroundColor: UIColor?,
        circular: Bool,
        textAttributes: [NSAttributedString.Key: AnyObject]?
    ) {
        let initials: String = getFirstPartFromString(for: string, substringEndUp: substringEndUp)
        let color: UIColor = (backgroundColor != nil) ? backgroundColor! : randomColor(for: string)
        let attributes: [NSAttributedString.Key: AnyObject] = (textAttributes != nil) ? textAttributes! : [
            NSAttributedString.Key.font: self.fontForFontName(name: nil),
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
        
        imageSnapshot(text: initials, backgroundColor: color, circular: circular, textAttributes: attributes) { [weak self] image in
            DispatchQueue.main.async {
                self?.image = image
            }
        }
    }
    
    private func fontForFontName(name: String?) -> UIFont {
        
        let fontSize = self.bounds.width * kFontResizingProportion
        guard let name = name else { return .systemFont(ofSize: fontSize) }
        guard let customFont = UIFont(name: name, size: fontSize) else { return .systemFont(ofSize: fontSize) }
        return customFont
    }
    
    private func imageSnapshot(text imageText: String, backgroundColor: UIColor, circular: Bool, textAttributes: [NSAttributedString.Key : AnyObject], completion: @escaping (UIImage) -> Void) {
        let bounds: CGRect = self.bounds
        let scale: CGFloat = UIScreen.main.scale
        
        var size: CGSize = self.bounds.size
        if (self.contentMode == .scaleToFill ||
            self.contentMode == .scaleAspectFill ||
            self.contentMode == .scaleAspectFit ||
            self.contentMode == .redraw) {
            
            size.width = (size.width * scale) / scale
            size.height = (size.height * scale) / scale
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            UIGraphicsBeginImageContextWithOptions(size, false, scale)
            
            guard let context: CGContext = UIGraphicsGetCurrentContext() else {
                completion(UIImage())
                return
            }
            context.setFillColor(backgroundColor.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
            
            // Draw text in the context
            let textSize: CGSize = imageText.size(withAttributes: textAttributes)
            
            imageText.draw(
                in: CGRect(
                    x: bounds.midX - textSize.width / 2,
                    y: bounds.midY - textSize.height / 2,
                    width: textSize.width,
                    height: textSize.height
                ),
                withAttributes: textAttributes
            )
            
            guard let snapshot: UIImage = UIGraphicsGetImageFromCurrentImageContext() else {
                completion(UIImage())
                return
            }
            UIGraphicsEndImageContext()
            completion(snapshot)
        }
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
    
    private func randomColorComponent() -> Int {
        let limit = kColorMaxComponent - kColorMinComponent
        return kColorMinComponent + Int(drand48() * Double(limit))
    }
    
    private func randomColor(for string: String) -> UIColor {
        srand48(string.hashValue)
        
        let red = CGFloat(randomColorComponent()) / 255.0
        let green = CGFloat(randomColorComponent()) / 255.0
        let blue = CGFloat(randomColorComponent()) / 255.0
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
}


